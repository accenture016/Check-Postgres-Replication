#!/bin/bash

# $Id: check_slave_replication.sh 3421 2013-08-09 07:52:44Z jmorano
# How Replication works:

# Master ->>>> streaming to ->>>> Standby -->> replay ->>> write to Standby disk

# Original writer and ideator: jmorano
# Rewritten by Fabio Pardi
# Edited bu Carlo Sacchi
# Version: August 2019
# Codename: carlos

# Nagios standard exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Passed parameters
## Primary (p_) and Standby (s_) DB Server Information
s_host=$1
s_port=$2
p_db=$3
p_host=$4
p_port=$5
db_user=$6
db_p_user=$7


## Limits are in bytes
# 1 WAL file is 16MB = 16777216 bytes

critical_limit=50331648 # 48 MB
warning_limit=33554432  # 32 MB


# Pre flight checks
if [ -z $s_host ] || [ -z $s_port ] || [ -z $p_db ] || [ -z $p_host ] || [ -z $p_port ] || [ -z $db_user ] || [ -z $db_p_user ]
then
    echo "Error: not all parameters are set!"
    echo 
    echo "Please use $0 standby_host standby_port db_name primary_host primary_port user"
    echo 
    echo "Eg: $0 10.10.10.2 5432 mydb 10.10.10.3 5432 myuser"
    exit 2
fi

if ! which bc > /dev/null  
then 
    echo "bc is not installed!" 
    exit 2 
fi

if ! which psql > /dev/null     
then
    echo "psql is not installed!"
    exit 2
fi

# End of checks

replay_lag=$(psql -U $db_user -p $db_p_user -h$s_host -p$s_port -A -t -c "SELECT pg_xlog_location_diff(pg_last_xlog_replay_location(), '0/0')" $p_db )  || exit $STATE_CRITICAL   # Replay
slave_lag=$(psql -U $db_user -p $db_p_user -h$s_host -p$s_port -A -t -c "SELECT pg_xlog_location_diff(pg_last_xlog_receive_location(), '0/0')" $p_db)  || exit $STATE_CRITICAL   # Receive
master_lag=$(psql -U $db_user -p $db_p_user -h$p_host -p$p_port -A -t -c "SELECT pg_xlog_location_diff(pg_current_xlog_location(), '0/0')" $p_db     )  || exit $STATE_CRITICAL   # Offset

# There are cases in which the connection and query are OK but nothing is returend. Eg: the wrong server is queried 
if [ -z $replay_lag ]
then
    echo "Replay lag returns empty. Is query running against a standby server?"
    exit $STATE_CRITICAL
fi

if [ -z $slave_lag ]
then
    echo "Slave lag returns empty. Is query running against a standby server?"
    exit $STATE_CRITICAL
fi

# During my tests, this case never happens, but I think is a good idea to cover it anyway
if [ -z $master_lag ]
then
    echo "Master lag returns empty. Something went wrong"
    exit $STATE_CRITICAL
fi


lag_receive_bytes=$(bc <<< $master_lag-$slave_lag)
lag_replay_bytes=$(bc <<< $slave_lag-$replay_lag)
lag_units=bytes
replay_units=bytes

receive_normalized=$lag_receive_bytes
replay_normalized=$lag_replay_bytes

# Print pretty numbers if number are high
if [ $lag_receive_bytes -gt 1048576 ] ; then
    # Use MBytes instead of bytes
    lag_units=MBytes
    receive_normalized=$(bc <<< $lag_receive_bytes/1048576)
fi

if [ $lag_replay_bytes -gt 1048576 ] ; then
    # Use MBytes instead of bytes
    replay_units=MBytes
    replay_normalized=$(bc <<< $lag_replay_bytes/1048576)
fi


if [[ $lag_receive_bytes -lt $warning_limit && $lag_replay_bytes -lt $warning_limit ]] ; then
    echo "OK: Standby is in sync (lag is $receive_normalized $lag_units)| MASTER:$master_lag Slave:$slave_lag Replay:$replay_lag"
    exit $STATE_OK
fi


##########################################
# Cases in which things are not OK
# Replication is not in sync and is critical

if [ $lag_receive_bytes -gt $critical_limit ] ; then
    echo "CRITICAL: Stream is behind of $receive_normalized $lag_units | Master: $master_lag Standby: $slave_lag Replay: $replay_lag"
    exit $STATE_CRITICAL
fi

# Replay is not in sync and is critical
if [ $lag_replay_bytes -gt $critical_limit ] ; then
    echo "CRITICAL: Replay on Standby is behind of $replay_normalized $lag_units | Master: $master_lag Standby: $slave_lag Replay: $replay_lag"
    exit $STATE_CRITICAL
fi

# Replication is not in sync and is warning
if [ $lag_receive_bytes -gt $warning_limit ] ; then
    echo "WARNING: Stream is behind of $receive_normalized $lag_units | Master: $master_lag Standby: $slave_lag Replay: $replay_lag"
    exit $STATE_WARNING
fi


# Replay is not in sync and is warning
if [ $lag_replay_bytes -gt $warning_limit ] ; then
    echo "WARNING: Replay on Standby is behind of $replay_normalized $lag_units | Master: $master_lag Standby: $slave_lag Replay: $replay_lag"
    exit $STATE_WARNING
fi

echo "Something somewhere went terribly wrong!"
exit $STATE_UNKNOWN
