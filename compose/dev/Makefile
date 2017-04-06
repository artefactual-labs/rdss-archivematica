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
	# These first two lines could be unnecessary if I do it from Dockerfile
	docker-compose exec --user="root" archivematica-storage-service sh -c "mkdir -p /var/archivematia/storage_service /db /src/storage_service/assets"
	docker-compose exec --user="root" archivematica-storage-service sh -c "chown -R archivematica:archivematica /var/archivematica /db /src/storage_service/assets"
	docker-compose exec archivematica-storage-service /src/storage_service/manage.py migrate --noinput
	docker-compose exec archivematica-storage-service /src/storage_service/manage.py collectstatic --noinput

bootstrap-mcp-server:
	# These first two lines could be unnecessary if I do it from Dockerfile
	docker-compose run --user=root --entrypoint=bash archivematica-mcp-server -c "cp -R /src/MCPServer/share/sharedDirectoryStructure/* /var/archivematica/sharedDirectory/"
	docker-compose run --user=root --entrypoint=bash archivematica-mcp-server -c "chown -R archivematica:archivematica /var/archivematica"

restart-mcp-services:
	docker-compose restart archivematica-mcp-server archivematica-mcp-client
