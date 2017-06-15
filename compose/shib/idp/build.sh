#!/bin/bash

BUILD_DIR="$(pwd)/build"

SHIB_IDP_DIR="${BUILD_DIR}/customized-shibboleth-idp"

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

CA_DIR="$(pwd)/../ca"

IDP_HOSTNAME=${IDP_HOSTNAME:-"idp.${DOMAIN_NAME}"}

mkdir -p ${BUILD_DIR}

if [ ! -d ${SHIB_IDP_DIR} ] ; then
	# Seed the IdP with parameters specific to our environment
	docker run --rm -it \
		-h ${IDP_HOSTNAME} \
		-v $(pwd)/bin:/setup/bin \
		-v $(pwd)/conf:/setup/conf \
		-v ${BUILD_DIR}:/ext-mount \
		-e DOMAIN_NAME=${DOMAIN_NAME} \
		unicon/shibboleth-idp /setup/bin/init-idp.sh
	
	# Ensure that we still have perms on the customized output
	# TODO I really don't like having sudo here, is there a way to avoid?
	sudo chown -R $(id -u):$(id -g) ${BUILD_DIR}
	chmod -R u+rwX ${BUILD_DIR}
fi

if [ ! -f "${BUILD_DIR}/${IDP_HOSTNAME}.csr" ] ; then
	# Configure our CSR
	cat > csr.conf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ dn ]
CN=${IDP_HOSTNAME}
C=GB
ST=London
L=London
emailAddress=admin@${DOMAIN_NAME}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${IDP_HOSTNAME}
URI.1 = https://${IDP_HOSTNAME}/idp/shibboleth

EOF
	# Generate a CSR for the IdP
	openssl req -nodes -new -newkey rsa \
		-config "$(pwd)/csr.conf" \
		-passin pass:12345 -passout pass:12345 \
		-keyout "${BUILD_DIR}/${IDP_HOSTNAME}.key" \
		-out "${BUILD_DIR}/${IDP_HOSTNAME}.csr"
	# Remove temporary CSR config
	rm -f csr.conf
fi

if [ ! -f "${BUILD_DIR}/${DOMAIN_NAME}-ca.crt" ] ; then
	# Generate a CA-signed cert for the IdP to present to browsers
	pushd "${CA_DIR}"
	tstamp="$(date +"%Y%m%d%H%M")"
	./sign.sh "${IDP_HOSTNAME}.${tstamp}" "${BUILD_DIR}/${IDP_HOSTNAME}.csr"
	pushd "domains/${DOMAIN_NAME}"
	cp "certs/${IDP_HOSTNAME}.${tstamp}.crt" "${BUILD_DIR}/${IDP_HOSTNAME}.crt"
	cp "certs/${DOMAIN_NAME}-ca.crt" "${BUILD_DIR}/${DOMAIN_NAME}-ca.crt"
	popd
	popd
fi

if [ ! -f "${BUILD_DIR}/${IDP_HOSTNAME}.cer" ] ; then
	# Convert cert from PEM to DER for Java to import
	openssl x509 -outform der \
		-in "${BUILD_DIR}/${DOMAIN_NAME}-ca.crt" \
		-out "${BUILD_DIR}/${DOMAIN_NAME}-ca.cer"
fi

# Bundle the key and certs into a P12 file
if [ ! -f ${SHIB_IDP_DIR}/credentials/idp-browser.p12 ] ; then
	openssl pkcs12 \
		-inkey "${BUILD_DIR}/${IDP_HOSTNAME}.key" -in "${BUILD_DIR}/${IDP_HOSTNAME}.crt" \
		-certfile "${BUILD_DIR}/${DOMAIN_NAME}-ca.crt" \
		-export -out "${SHIB_IDP_DIR}/credentials/idp-browser.p12" \
		-passout pass:12345
fi

# Use the same key and cert for the backchannel
if [ ! -f "${SHIB_IDP_DIR}/credentials/idp-backchannel.p12" ] ; then
	cp -p "${SHIB_IDP_DIR}/credentials/idp-browser.p12" \
		"${SHIB_IDP_DIR}/credentials/idp-backchannel.p12"
fi
if [ ! -f "${SHIB_IDP_DIR}/credentials/idp-encryption.crt" ] ; then
	cp -p "${BUILD_DIR}/${IDP_HOSTNAME}.crt" \
		"${SHIB_IDP_DIR}/credentials/idp-encryption.crt"
	cp -p "${BUILD_DIR}/${IDP_HOSTNAME}.key" \
		"${SHIB_IDP_DIR}/credentials/idp-encryption.key"
fi
if [ ! -f "${SHIB_IDP_DIR}/credentials/idp-signing.crt" ] ; then
	cp -p "${BUILD_DIR}/${IDP_HOSTNAME}.crt" \
		"${SHIB_IDP_DIR}/credentials/idp-signing.crt"
	cp -p "${BUILD_DIR}/${IDP_HOSTNAME}.key" \
		"${SHIB_IDP_DIR}/credentials/idp-signing.key"
fi
