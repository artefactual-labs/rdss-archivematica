#!/bin/bash

BUILD_DIR=$(pwd)/build
SHIB_IDP_DIR=${BUILD_DIR}/../../idp/build/customized-shibboleth-idp/

DOMAIN_NAME="example.ac.uk"

CA_DIR=${BUILD_DIR}/../../ca

NGINX_HOSTNAME="myapp.${DOMAIN_NAME}"

mkdir -p ${BUILD_DIR}

# Copy Archivematica nginx config
cp ${BUILD_DIR}/../../../dev/etc/nginx/archivematica.conf ${BUILD_DIR}/

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
	openssl req -nodes -new -newkey rsa \
		-config "$(pwd)/csr.conf" \
		-passin pass:12345 -passout pass:12345 \
		-keyout "${BUILD_DIR}/sp-key.pem" \
		-out "${BUILD_DIR}/${NGINX_HOSTNAME}.csr"
	# Remove temporary CSR config
	rm -f csr.conf
fi

# Sign CSR to create the certificate
if [ ! -f ${BUILD_DIR}/sp-cert.pem ] ; then
	pushd "${CA_DIR}"
	tstamp="$(date +"%Y%m%d%H%M")"
	./sign.sh "${NGINX_HOSTNAME}.${tstamp}" "${BUILD_DIR}/${NGINX_HOSTNAME}.csr"
	cp "certs/${NGINX_HOSTNAME}.${tstamp}.crt" "${BUILD_DIR}/sp-cert.pem"
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
		-key "${BUILD_DIR}/sp-key.pem" \
		-out "${BUILD_DIR}/web.${NGINX_HOSTNAME}.csr"
	# Remove temporary CSR config
	rm -f csr.conf
fi

# Sign CSR to create the certificate
if [ ! -f ${BUILD_DIR}/sp-web-cert.pem ] ; then
	pushd "${CA_DIR}"
	tstamp="$(date +"%Y%m%d%H%M")"
	./sign.sh "web.${NGINX_HOSTNAME}.${tstamp}" "${BUILD_DIR}/web.${NGINX_HOSTNAME}.csr"
	cp "certs/web.${NGINX_HOSTNAME}.${tstamp}.crt" "${BUILD_DIR}/sp-web-cert.pem"
	popd
fi

# Copy our CA certificate
if [ ! -f ${BUILD_DIR}/${DOMAIN_NAME}-ca.crt ] ; then
	cp "${CA_DIR}/certs/${DOMAIN_NAME}-ca.crt" "${BUILD_DIR}/${DOMAIN_NAME}-ca.crt"
fi

# Copy Shibboleth IdP metadata into our build dir
rm -f ${BUILD_DIR}/idp-metadata.xml
cp -p ${SHIB_IDP_DIR}/metadata/idp-metadata.xml \
	${BUILD_DIR}/idp-metadata.xml

# Build our custom Docker image
docker build --tag="arkivum/shibboleth-nginx" \
	--build-arg DOMAIN_NAME="${DOMAIN_NAME}" \
	.
