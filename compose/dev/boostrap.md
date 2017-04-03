Manually for now: (**undesirable**)

Create MySQL database:

    $ docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "CREATE DATABASE MCP;"

Create MySQL user:

    $ docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"

Populate database from archivematica-dashboard:

    $ docker-compose exec archivematica-dashboard /src/dashboard/src/manage.py migrate

Populate database from archivematica-storage-service:

    $ docker-compose exec --user="root" archivematica-storage-service sh -c "mkdir /db && chown archivematica:archivematica /db"
    $ docker-compose exec archivematica-storage-service /src/storage_service/manage.py migrate

Populate watched directories:

    $ docker-compose run --user=root --entrypoint=bash archivematica-mcp-server -c "cp -R /src/MCPServer/share/sharedDirectoryStructure/* /var/archivematica/sharedDirectory/"
    $ docker-compose run --user=root --entrypoint=bash archivematica-mcp-server -c "chown -R archivematica:archivematica /var/archivematica"

Restart services:

    $ docker-compose restart archivematica-mcp-server archivematica-mcp-client

Install dashboard (downlaod FPR rules)
