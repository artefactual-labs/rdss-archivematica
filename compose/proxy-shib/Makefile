.DEFAULT_GOAL := build

SUB_DIRS := $(sort $(wildcard */))

BASE_DIR ?= ${CURDIR}

DEFAULT_COMPOSE_FILE = $(shell realpath ../docker-compose.proxy-shib.yml)

COMPOSE_FILE ?= "${DEFAULT_COMPOSE_FILE}"

DOMAIN_NAME ?= "example.ac.uk"

all: destroy up bootstrap list

bootstrap: bootstrap-nginx-shib

bootstrap-nginx-shib:
	# Update Shib SP attrChecker script based on config
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose exec nginx \
		/bin/sh -c "cd /etc/shibboleth && ./attrChecker.pl"

build:
	# Prepare the image and configuration for each service
	$(foreach DIR, $(SUB_DIRS), echo ">>> Entering '$(BASE_DIR)/$(DIR)' ... " && \
		cd $(BASE_DIR)/$(DIR) && \
		[ ! -f ./build.sh ] || ./build.sh && \
		cd $(BASE_DIR) && \
		echo ">>> Left '$(BASE_DIR)/$(DIR)'." ;)
	# Build the services. These depend on those in dev, so include that config too
	COMPOSE_FILE=${COMPOSE_FILE} docker-compose build
	
config:
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose config

destroy:
	# Stop containers and remove volumes
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose down --volumes
	# Clear all build files for nginx
	$(foreach DIR, nginx, rm -Rf $(BASE_DIR)/$(DIR)/build/* ;)

list:
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose ps

up: build
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose up -d

.PHONY: all bootstrap bootstrap-ldap bootstrap-nginx-shib build destroy list up
