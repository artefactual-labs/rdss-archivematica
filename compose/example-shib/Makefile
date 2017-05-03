.DEFAULT_GOAL := build

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

SUB_DIRS := $(sort $(wildcard */))

all: destroy bootstrap

bootstrap: up
	# Install LDAP edu schema
	docker-compose exec example-ldap \
		/usr/local/ldap/edu/install.sh
	# Install LDAP demo users
	docker-compose exec example-ldap \
		ldapadd \
			-D "cn=admin,dc=example,dc=ac,dc=uk" -w admin \
			-f "/usr/local/ldap/example.ac.uk.ldif"

build:
	# Prepare the image and configuration for each service
	$(foreach DIR, $(SUB_DIRS), cd $(ROOT_DIR)/$(DIR) && ./build.sh && cd $(ROOT_DIR) ;)
	# Build the services
	docker-compose build
	
destroy:
	# Stop containers and remove volumes
	docker-compose stop
	docker-compose down --volumes
	# Clear all build files for IdP and SP
	$(foreach DIR, idp nginx sp, sudo rm -Rf $(ROOT_DIR)/$(DIR)/build/* ;)

nuke-ca:
	# Nuke the Example CA (not necessary for every rebuild)
	cd $(ROOT_DIR)/ca && ./nuke.sh && cd $(ROOT_DIR)

up: build
	docker-compose up -d

.PHONY: all bootstrap build destroy nuke-ca up
