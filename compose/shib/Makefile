.DEFAULT_GOAL := build

BASE_DIR ?= ${CURDIR}

DOMAIN_NAME ?= "example.ac.uk"

all: destroy build

build:
	# Prepare the configuration for each service
	$(foreach DIR, ca idp ldap, echo ">>> Entering '$(BASE_DIR)/$(DIR)' ... " && \
		cd $(BASE_DIR)/$(DIR) && ./build.sh && cd $(BASE_DIR) && \
		echo ">>> Left '$(BASE_DIR)/$(DIR)'." ;)
	
destroy:
	# Clear all build files for IdP and LDAP
	$(foreach DIR, idp ldap, sudo rm -Rf $(BASE_DIR)/$(DIR)/build/* ;)

nuke-ca:
	# Nuke the Certificate Authority (not necessary for every rebuild)
	cd $(BASE_DIR)/ca && ./nuke.sh && cd $(BASE_DIR)

.PHONY: all build destroy nuke-ca
