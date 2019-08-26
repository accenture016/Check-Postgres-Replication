# check_postgres_replication
Script to check postgres replication

Original by https://exchange.nagios.org/directory/Plugins/Databases/PostgresQL/Check-postgres-replication/details

Edited adding password as variable

HOW TO USE:

The script needs  bc (Basic Calculator) (yum install bc -y)

Set Permissions xr permission (chmod 700 check_postgres_rep.sh, 555 etc..)

./check_postgres_rep.sh ip_host_slave slave_port db_postgres ip_master port_master user password
