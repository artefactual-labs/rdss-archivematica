.DEFAULT_GOAL := build

SUB_DIRS := $(sort $(wildcard */))

BASE_DIR ?= ${CURDIR}

DEFAULT_COMPOSE_FILE = $(shell realpath ../docker-compose.example-shib.yml)

COMPOSE_FILE ?= "${DEFAULT_COMPOSE_FILE}"

DOMAIN_NAME ?= "example.ac.uk"

LDAP_DOMAIN = $(shell echo -n dc=$(DOMAIN_NAME) | sed 's/[.]/,dc=/g')

all: destroy up bootstrap list

bootstrap:
	# Install LDAP edu schema
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose exec ldap \
		/usr/local/ldap/edu/install.sh
	# Install LDAP demo users
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose exec ldap \
		ldapadd \
			-D "cn=admin,$(LDAP_DOMAIN)" -w admin \
			-f "/usr/local/ldap/demo-users.ldif"

build:
	# Prepare the image and configuration for each service
	$(foreach DIR, $(SUB_DIRS), echo ">>> Entering '$(BASE_DIR)/$(DIR)' ... " && \
		cd $(BASE_DIR)/$(DIR) && \
		[ ! -f ./build.sh ] || ./build.sh && \
		cd $(BASE_DIR) && \
		echo ">>> Left '$(BASE_DIR)/$(DIR)'." ;)
	# Build the services
	# We specify compose file explicitly, we don't want to build any other
	# container sets
	COMPOSE_FILE=${DEFAULT_COMPOSE_FILE} docker-compose build
	
config:
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose config

destroy:
	# Stop containers and remove volumes
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose down --volumes
	# Clear all build files for IdP, nginx and SP
	$(foreach DIR, idp nginx sp, sudo rm -Rf $(BASE_DIR)/$(DIR)/build/* ;)

list:
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose ps

nuke-ca:
	# Nuke the Certificate Authority (not necessary for every rebuild)
	cd $(BASE_DIR)/ca && ./nuke.sh && cd $(BASE_DIR)

verify:
	@echo "COMPOSE_DIRS = ${COMPOSE_DIRS}"
	@echo "COMPOSE_FILE = ${COMPOSE_FILE}"
	@echo "SHIBBOLETH_CONFIG = ${SHIBBOLETH_CONFIG}"

up: build
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose up -d

.PHONY: all bootstrap build destroy list nuke-ca verify up
