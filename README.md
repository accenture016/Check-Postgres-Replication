# Check Postgres Replication

Script to check postgres replication

![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![Buils](https://img.shields.io/badge/build-stable-green.svg)
![GitHub file size in bytes](https://img.shields.io/github/size/accenture016/Check-Postgres-Replication/Check_Postgres_Replication.sh)

Tested on PostrgreSQL 9.5

<img src="https://www.postgresql.org/media/img/about/press/elephant.png" width="50" height="50">

Original by https://exchange.nagios.org/directory/Plugins/Databases/PostgresQL/Check-postgres-replication/details

Edited by adding password as variable parameter on CLI ./myscript parameter1 parameter2... password

HOW TO USE:

The script needs  bc (Basic Calculator) (yum install bc -y)

Set Permissions xr permission (chmod 700 check_postgres_rep.sh, 555 etc..)

./check_postgres_rep.sh ip_host_slave slave_port db_postgres ip_master port_master user password
