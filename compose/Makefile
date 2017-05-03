.DEFAULT_GOAL := build

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# The directories to use as part of the docker-compose build. May be a list.
COMPOSE_DIRS=dev

# Do we want to include the example-shibboleth services?
ifdef EXAMPLE_SHIBBOLETH
	override COMPOSE_DIRS += example-shib
endif

# Set the docker-compose COMPOSE_FILE env var to include the config from each
# dir in COMPOSE_DIRS
override COMPOSE_FILE ?= $(shell echo \
	"$(foreach DIR, $(COMPOSE_DIRS),$(ROOT_DIR)/$(DIR)/docker-compose.yml)"\
	| tr ' ' ':')
export COMPOSE_FILE

all: destroy up bootstrap
	docker-compose ps

bootstrap build destroy up:
	$(foreach DIR, $(COMPOSE_DIRS), $(MAKE) -C $(DIR) $@ ;)

watch:
	docker-compose logs -f

watch-idp:
	docker-compose logs -f example-idp

watch-sp:
	docker-compose logs -f example-sp

.PHONY: all bootstrap build destroy up
