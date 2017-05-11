.DEFAULT_GOAL := build

# The directories to use as part of the docker-compose build. May be a list.
COMPOSE_DIRS=dev

BASE_DIR ?= ${CURDIR}

# Do we want to include the example-shibboleth services?
ifdef EXAMPLE_SHIBBOLETH
	override COMPOSE_DIRS += example-shib
endif

# Set the docker-compose COMPOSE_FILE env var to include the config from each
# dir in COMPOSE_DIRS
override COMPOSE_FILE ?= $(shell echo \
	"$(foreach DIR, $(COMPOSE_DIRS),${CURDIR}/docker-compose.$(DIR).yml)"\
	| tr ' ' ':')
export COMPOSE_FILE

all: destroy bootstrap list

bootstrap: up
	$(foreach DIR, $(COMPOSE_DIRS), $(MAKE) -C $(DIR) $@ ;)

build config destroy:
	$(foreach DIR, $(COMPOSE_DIRS), $(MAKE) -C $(DIR) $@ ;)
	@sleep 10

list:
	docker-compose ps

up: build
	docker-compose up -d

watch:
	docker-compose logs -f

watch-idp:
	docker-compose logs -f example-idp

watch-nginx:
	docker-compose logs -f 

watch-sp:
	docker-compose logs -f example-sp

.PHONY: all bootstrap build config destroy list watch watch-idp watch-sp up
