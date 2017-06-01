#!/bin/bash

BUILD_DIR=$(pwd)/build

SHIB_DIR="${BUILD_DIR}/../../../shib"
SHIB_IDP_DIR="${SHIB_DIR}/idp/build/customized-shibboleth-idp/"

SHIB_SP1_DIR=${BUILD_DIR}/sp1

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

CA_DIR=${SHIB_DIR}/ca

SP1_HOSTNAME="sp1.${DOMAIN_NAME}"


mkdir -p ${BUILD_DIR}

if [ ! -d ${SHIB_SP1_DIR} ] ; then
	# Clone the SP1 provider from github
	pushd ${BUILD_DIR}
	git clone https://github.com/serglopatin/sp1/
	popd
	# Update the SP1 hostname in config
	sed -i "s/HOSTNAME = .*/HOSTNAME = \"${SP1_HOSTNAME}\"/" \
		${SHIB_SP1_DIR}/sp1/common_settings.py
fi

if [ ! -f "${BUILD_DIR}/${SP1_HOSTNAME}.csr" ] ; then
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
CN=${SP1_HOSTNAME}
C=GB
ST=London
L=London
emailAddress=admin@${DOMAIN_NAME}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${SP1_HOSTNAME}

EOF
	# Generate a CSR for the SP
	openssl req -nodes -new -newkey rsa \
		-config "$(pwd)/csr.conf" \
		-passin pass:12345 -passout pass:12345 \
		-keyout "${SHIB_SP1_DIR}/sp1/sp1_key.key" \
		-out "${BUILD_DIR}/${SP1_HOSTNAME}.csr"
	# Remove temporary CSR config
	rm -f csr.conf
fi

# Generate certs
if [ ! -f "${BUILD_DIR}/${DOMAIN_NAME}-ca.crt" ] ; then
	pushd "${CA_DIR}"
	tstamp="$(date +"%Y%m%d%H%M")"
	./sign.sh "${SP1_HOSTNAME}.${tstamp}" "${BUILD_DIR}/${SP1_HOSTNAME}.csr"
	pushd "domains/${DOMAIN_NAME}"
	cp "certs/${SP1_HOSTNAME}.${tstamp}.crt" "${SHIB_SP1_DIR}/sp1/sp1_cert.pem"
	cp "certs/${DOMAIN_NAME}-ca.crt" "${BUILD_DIR}/${DOMAIN_NAME}-ca.crt"
	popd
	popd
fi

# Copy Shibboleth IdP metadata into our SP1 dir
rm -f ${SHIB_SP1_DIR}/sp1/idp_metadata.xml
cp -p ${SHIB_IDP_DIR}/metadata/idp-metadata.xml \
	${SHIB_SP1_DIR}/sp1/idp_metadata.xml
