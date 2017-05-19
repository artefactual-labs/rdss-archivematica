#!/bin/bash

BUILD_DIR=$(pwd)/build

SHIB_DIR="${BUILD_DIR}/../../../shib"
SHIB_IDP_DIR=${BUILD_DIR}/../../idp/build/customized-shibboleth-idp/

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

CA_DIR=${SHIB_DIR}/ca

NGINX_HOSTNAME=${NGINX_HOSTNAME:-"archivematica.${DOMAIN_NAME}"}

mkdir -p ${BUILD_DIR}

# Create private key for Shibboleth SP services
if [ ! -f "${BUILD_DIR}/sp-key.${NGINX_HOSTNAME}.pem" ] ; then
	openssl genrsa -out "${BUILD_DIR}/sp-key.${NGINX_HOSTNAME}.pem" 2048
fi

# Create CSR for Shibboleth SP services
if [ ! -f "${BUILD_DIR}/${NGINX_HOSTNAME}.csr" ] ; then
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
CN=${NGINX_HOSTNAME}
C=GB
ST=London
L=London
emailAddress=admin@${DOMAIN_NAME}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${NGINX_HOSTNAME}

EOF
	# Generate a CSR for Shibboleth SP services
	openssl req -nodes -new \
		-config "$(pwd)/csr.conf" \
		-passin pass:12345 -passout pass:12345 \
		-key "${BUILD_DIR}/sp-key.${NGINX_HOSTNAME}.pem" \
		-out "${BUILD_DIR}/${NGINX_HOSTNAME}.csr"
	# Remove temporary CSR config
	rm -f csr.conf
fi

# Sign CSR to create the certificate
if [ ! -f ${BUILD_DIR}/sp-cert.${NGINX_HOSTNAME}.pem ] ; then
	pushd "${CA_DIR}"
	tstamp="$(date +"%Y%m%d%H%M")"
	./sign.sh "${NGINX_HOSTNAME}.${tstamp}" "${BUILD_DIR}/${NGINX_HOSTNAME}.csr"
	pushd "domains/${DOMAIN_NAME}"
	cp "certs/${NGINX_HOSTNAME}.${tstamp}.crt" "${BUILD_DIR}/sp-cert.${NGINX_HOSTNAME}.pem"
	popd
	popd
fi

# Create CSR for nginx SSL
if [ ! -f "${BUILD_DIR}/web.${NGINX_HOSTNAME}.csr" ] ; then
	# Configure our CSR
	cat > csr.conf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ dn ]
CN=${NGINX_HOSTNAME}
C=GB
ST=London
L=London
emailAddress=admin@${DOMAIN_NAME}

EOF
	# Generate a CSR for Shibboleth SP services (reusing existing key)
	openssl req -nodes -new \
		-config "$(pwd)/csr.conf" \
		-passin pass:12345 -passout pass:12345 \
		-key "${BUILD_DIR}/sp-key.${NGINX_HOSTNAME}.pem" \
		-out "${BUILD_DIR}/web.${NGINX_HOSTNAME}.csr"
	# Remove temporary CSR config
	rm -f csr.conf
fi

# Sign CSR to create the certificate
if [ ! -f ${BUILD_DIR}/sp-web-cert.${NGINX_HOSTNAME}.pem ] ; then
	pushd "${CA_DIR}"
	tstamp="$(date +"%Y%m%d%H%M")"
	./sign.sh "web.${NGINX_HOSTNAME}.${tstamp}" "${BUILD_DIR}/web.${NGINX_HOSTNAME}.csr"
	pushd "domains/${DOMAIN_NAME}"
	cp "certs/web.${NGINX_HOSTNAME}.${tstamp}.crt" "${BUILD_DIR}/sp-web-cert.${NGINX_HOSTNAME}.pem"
	popd
	popd
fi

# Use templated shibboleth-nginx image to build image for this domain and SP
pushd ${BUILD_DIR}/../../../shib/nginx/ && ./build.sh \
	-d ${DOMAIN_NAME} \
	-c "$(readlink -f ${CA_DIR}/domains/${DOMAIN_NAME}/certs/${DOMAIN_NAME}-ca.crt)" \
	-k "${BUILD_DIR}/sp-key.${NGINX_HOSTNAME}.pem" \
	-n "$(readlink -f ${BUILD_DIR}/../etc/nginx/conf.d/am-shib.conf.tpl)" \
	-s "${BUILD_DIR}/sp-cert.${NGINX_HOSTNAME}.pem" \
	-w "${BUILD_DIR}/sp-web-cert.${NGINX_HOSTNAME}.pem" \
	-x "$(readlink -f ${BUILD_DIR}/../etc/shibboleth/shibboleth2.xml.tpl)" \
&& popd

