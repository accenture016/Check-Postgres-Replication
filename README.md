# Check Postgres Replication

Script to check postgres replication

Tested on PostrgreSQL 9.5

Original by https://exchange.nagios.org/directory/Plugins/Databases/PostgresQL/Check-postgres-replication/details

Edited by adding password as variable parameter on CLI ./myscript parameter1 parameter2... password

HOW TO USE:

The script needs  bc (Basic Calculator) (yum install bc -y)

Set Permissions xr permission (chmod 700 check_postgres_rep.sh, 555 etc..)

./check_postgres_rep.sh ip_host_slave slave_port db_postgres ip_master port_master user password
