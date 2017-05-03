.DEFAULT_GOAL := build

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

all: destroy bootstrap
	docker-compose ps

destroy:
	docker-compose stop
	docker-compose down --volumes

build:
	docker-compose build

bootstrap-storage-service:
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "DROP DATABASE IF EXISTS SS;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "CREATE DATABASE SS;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "GRANT ALL ON SS.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				migrate --noinput
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				create_user \
					--username="test" \
					--password="test" \
					--email="test@test.com" \
					--api-key="test"

bootstrap: build bootstrap-dashboard bootstrap-storage-service restart-mcp-services

bootstrap-dashboard:
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "DROP DATABASE IF EXISTS MCP;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "CREATE DATABASE MCP;"
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				migrate --noinput
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				install \
					--username="test" \
					--password="test" \
					--email="test@test.com" \
					--org-name="test" \
					--org-id="test" \
					--api-key="test" \
					--ss-url="http://archivematica-storage-service:8000" \
					--ss-user="test" \
					--ss-api-key="test"

restart-mcp-services:
	docker-compose restart archivematica-mcp-server archivematica-mcp-client

up: build
	$(foreach DIR, $(COMPOSE_DIRS), docker-compose up -d ;)
	@echo -n "Waiting 30 seconds for services to finish starting..."
	@sleep 30
	@echo " done."

watch-am:
	docker-compose logs -f archivematica-mcp-server archivematica-mcp-client archivematica-dashboard

watch-ss:
	docker-compose logs -f archivematica-storage-service

.PHONY: default destroy bootstrap build bootstrap-dashboard bootstrap-storage-service restart-mcp-services
