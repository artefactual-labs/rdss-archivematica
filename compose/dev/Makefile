.DEFAULT_GOAL := build

all: destroy build up bootstrap

destroy:
	docker-compose stop
	docker-compose down --volumes

build:
	docker-compose build

up:
	docker-compose up -d
	@echo -n "Waiting 30 seconds for services to finish starting..."
	@sleep 30
	@echo " done."

bootstrap: bootstrap-dashboard bootstrap-storage-service restart-mcp-services

bootstrap-dashboard:
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "DROP DATABASE IF EXISTS MCP;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "CREATE DATABASE MCP;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				migrate --noinput

bootstrap-storage-service:
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "DROP DATABASE IF EXISTS SS;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "CREATE DATABASE SS;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "GRANT ALL ON SS.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				migrate --noinput

restart-mcp-services:
	docker-compose restart archivematica-mcp-server archivematica-mcp-client

.PHONY: default destroy bootstrap build bootstrap-dashboard bootstrap-storage-service restart-mcp-services
