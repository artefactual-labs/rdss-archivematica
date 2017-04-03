destroy:
	docker-compose stop
	docker-compose down --volumes

bootstrap: bootstrap-dashboard bootstrap-storage-service bootstrap-mcp-server restart-mcp-services

bootstrap-dashboard:
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "DROP DATABASE IF EXISTS MCP;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "CREATE DATABASE MCP;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose exec archivematica-dashboard /src/dashboard/src/manage.py migrate --noinput

bootstrap-storage-service:
	docker-compose exec --user="root" archivematica-storage-service sh -c "mkdir /db; chown archivematica:archivematica /db"
	docker-compose exec --user="root" archivematica-storage-service sh -c "mkdir -p /var/archivematica/storage_service; chown -R archivematica:archivematica /var/archivematica"
	docker-compose exec --user="root" archivematica-storage-service sh -c "mkdir /src/storage_service/assets; chown archivematica:archivematica /src/storage_service/assets"
	docker-compose exec archivematica-storage-service /src/storage_service/manage.py migrate --noinput
	docker-compose exec archivematica-storage-service /src/storage_service/manage.py collectstatic --noinput

bootstrap-mcp-server:
	docker-compose run --user=root --entrypoint=bash archivematica-mcp-server -c "cp -R /src/MCPServer/share/sharedDirectoryStructure/* /var/archivematica/sharedDirectory/"
	docker-compose run --user=root --entrypoint=bash archivematica-mcp-server -c "chown -R archivematica:archivematica /var/archivematica"

restart-mcp-services:
	docker-compose restart archivematica-mcp-server archivematica-mcp-client
