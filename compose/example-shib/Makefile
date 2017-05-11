.DEFAULT_GOAL := build

SUB_DIRS := $(sort $(wildcard */))

BASE_DIR ?= ${CURDIR}

DEFAULT_COMPOSE_FILE = "../docker-compose.example-shib.yml"

COMPOSE_FILE ?= "${DEFAULT_COMPOSE_FILE}"

all: destroy bootstrap

bootstrap: up
	# Install LDAP edu schema
	docker-compose exec ldap /usr/local/ldap/edu/install.sh
	# Install LDAP demo users
	docker-compose exec ldap \
		ldapadd \
			-D "cn=admin,dc=example,dc=ac,dc=uk" -w admin \
			-f "/usr/local/ldap/example.ac.uk.ldif"

build:
	# Prepare the image and configuration for each service
	$(foreach DIR, $(SUB_DIRS), cd $(BASE_DIR)/$(DIR) && \
			[ ! -f ./build.sh ] || ./build.sh && \
			cd $(BASE_DIR) ;)
	# Build the services
	# We specify compose file explicitly, we don't want to build any other
	# container sets
	COMPOSE_FILE=${DEFAULT_COMPOSE_FILE} docker-compose build
	
config:
	docker-compose config

destroy:
	# Stop containers and remove volumes
	docker-compose stop
	docker-compose down --volumes
	# Clear all build files for IdP and SP
	$(foreach DIR, idp nginx sp, sudo rm -Rf $(BASE_DIR)/$(DIR)/build/* ;)

list:
	docker-compose ps

nuke-ca:
	# Nuke the Example CA (not necessary for every rebuild)
	cd $(BASE_DIR)/ca && ./nuke.sh && cd $(BASE_DIR)

up: build
	docker-compose up -d

.PHONY: all bootstrap build destroy list nuke-ca up
