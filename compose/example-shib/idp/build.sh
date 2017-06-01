#!/bin/bash

BUILD_DIR=$(pwd)/build
SHIB_DIR="${BUILD_DIR}/../../../shib"

mkdir -p ${BUILD_DIR}

# Generate the IdP metadata providers XML from our service providers json
$SHIB_DIR/idp-metadata-providers.py $(readlink -f ./etc/service-providers.json) \
	> ${BUILD_DIR}/metadata-providers.xml
