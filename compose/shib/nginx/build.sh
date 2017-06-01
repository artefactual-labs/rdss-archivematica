#!/bin/bash

usage() {
	echo "Usage: $(basename $0) <arguments>"
	echo "Required arguments:"
	echo "-c    The path to the certificate file for the CA for the domain."
	echo "-d    The domain that the CA (and therefore each host) belongs to."
	echo "-k    The path to the key file for the SP to use."
	echo "-n    The path to the nginx.conf template file to use."
	echo "-s    The path to the certificate file for the SP to use."
	echo "-w    The path to the certificate file for the SP web UI to use."
	echo "-x    The path to the shibboleth2.xml template file to use."
	echo "Example:"
	echo "   $(basename $0) -c /tmp/example-ca.crt -d example.com \\"
	echo "     -k /tmp/sp-key.pem -s /tmp/sp-cert.pem -w /tmp/sp-web-cert.pem \\"
	echo "     -n /tmp/nginx.conf.tpl -x /tmp/shibboleth2.xml.tpl"
}

# Use existing environment variable values if set. These will be overriden by
# command line args.
CA_CERT_FILE=${CA_CERT_FILE:-}
DOMAIN_NAME=${DOMAIN_NAME:-}
NGINX_CONF_TEMPLATE_FILE=${NGINX_CONF_TEMPLATE_FILE:-}
SHIBBOLETH_CONF_TEMPLATE_FILE=${SHIBBOLETH_CONF_TEMPLATE_FILE:-}
SP_CERT_FILE=${SP_CERT_FILE:-}
SP_KEY_FILE=${SP_KEY_FILE:-}
SP_WEB_CERT_FILE=${SP_WEB_CERT_FILE:-}

# Get arguments from command line
while getopts ":c:d:k:n:s:w:x:" o; do
	case "${o}" in
	c)
		CA_CERT_FILE="${OPTARG}"
		;;
	d)
		DOMAIN_NAME="${OPTARG}"
		;;
	k)
		SP_KEY_FILE="${OPTARG}"
		;;
	n)
		NGINX_CONF_TEMPLATE_FILE="${OPTARG}"
		;;
	s)
		SP_CERT_FILE="${OPTARG}"
		;;
	w)
		SP_WEB_CERT_FILE="${OPTARG}"
		;;
	x)
		SHIBBOLETH_CONF_TEMPLATE_FILE="${OPTARG}"
		;;
	*)
		echo "${o} = ${OPTARG}"
		usage
		;;
	esac
done

echo "DOMAIN_NAME = $DOMAIN_NAME"
echo "CA_CERT_FILE = $CA_CERT_FILE"
echo "NGINX_CONF_TEMPLATE_FILE = $NGINX_CONF_TEMPLATE_FILE"
echo "SHIBBOLETH_CONF_TEMPLATE_FILE = $SHIBBOLETH_CONF_TEMPLATE_FILE"
echo "SP_CERT_FILE = $SP_CERT_FILE"
echo "SP_KEY_FILE = $SP_KEY_FILE"
echo "SP_WEB_CERT_FILE = $SP_WEB_CERT_FILE"

if [ -n "$DOMAIN_NAME" ] && [ -n "$CA_CERT_FILE" ] \
	&& [ -n "$NGINX_CONF_TEMPLATE_FILE" ] && [ -n "$SP_CERT_FILE" ] \
	&& [ -n "$SP_KEY_FILE" ] && [ -n "$SP_WEB_CERT_FILE" ] ; then
		
	# Collate everything together into a single context for Docker to use
	rm -Rf ctx
	mkdir -p ctx
	cp -p "Dockerfile" ctx/
	cp -pr etc ctx/
	cp -p "$CA_CERT_FILE" ctx/
	cp -p "$NGINX_CONF_TEMPLATE_FILE" ctx/
	cp -p "$SHIBBOLETH_CONF_TEMPLATE_FILE" ctx/
	cp -p "$SP_CERT_FILE" ctx/
	cp -p "$SP_KEY_FILE" ctx/
	cp -p "$SP_WEB_CERT_FILE" ctx/
	
	# Build our custom Docker image
	docker build --tag="arkivum/shibboleth-nginx:${DOMAIN_NAME}" \
		--build-arg CA_CERT_FILE="$(basename ${CA_CERT_FILE})" \
		--build-arg DOMAIN_NAME="${DOMAIN_NAME}" \
		--build-arg NGINX_CONF_TEMPLATE_FILE="$(basename $NGINX_CONF_TEMPLATE_FILE)" \
		--build-arg SHIBBOLETH_CONF_TEMPLATE_FILE="$(basename $SHIBBOLETH_CONF_TEMPLATE_FILE)" \
		--build-arg SP_CERT_FILE="$(basename ${SP_CERT_FILE})" \
		--build-arg SP_KEY_FILE="$(basename ${SP_KEY_FILE})" \
		--build-arg SP_WEB_CERT_FILE="$(basename ${SP_WEB_CERT_FILE})" \
		$(pwd)/ctx/
else
	echo "You must specify all required arguments."
	usage
fi
