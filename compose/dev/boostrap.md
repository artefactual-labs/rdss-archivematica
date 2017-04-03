Manually for now: (**undesirable**)

Create MySQL database:

    $ docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "CREATE DATABASE MCP;"

Create MySQL user:

    $ docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"

Populate database from archivematica-dashboard:

    $ docker-compose exec archivematica-dashboard /src/dashboard/src/manage.py migrate

Populate watched directories:

Restart services:

    $ docker-compose restart archivematica-mcp-server archivematica-mcp-client

Install dashboard (downlaod FPR rules)
