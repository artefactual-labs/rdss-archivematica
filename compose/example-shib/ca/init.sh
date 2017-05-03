#!/bin/bash

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

CA_NAME=${DOMAIN_NAME}-ca

CA_COMMONNAME="Example University CA"
CA_ORGANIZATION="Example University"
CA_CITY="London"
CA_STATE="London"
CA_COUNTRY="GB"
CA_EMAIL="admin@${DOMAIN_NAME}"

mkdir -p certs
mkdir -p db
mkdir -p export
mkdir -p newcerts
mkdir -p private

# Create the required CA database files
if [ ! -f db/index.txt ] ; then
    touch db/index.txt
fi
if [ ! -f db/serial ] ; then
    date "+%Y%m%d%k%M%S01" > db/serial
fi

if [ ! -f db/crlnumber ] ; then
    echo "01" > db/crlnumber
fi

# Generate a passphrase
passwd="$(dd if=/dev/urandom ibs=1024 count=1 >/dev/null 2>&1 | openssl passwd stdin)"
if [ ! -f private/$CA_NAME.key.passphrase ] ; then
    echo "$passwd" > private/$CA_NAME.key.passphrase
else
    passwd="$(cat private/$CA_NAME.key.passphrase)"
fi

# Create the CA private key
if [ ! -f private/$CA_NAME.key ] ; then
    openssl genrsa -des3 -passout pass:"$passwd" -out private/$CA_NAME.key 4096
fi

# Create the CA public certificate
if [ ! -f certs/$CA_NAME.crt ] ; then
    openssl req -new -x509 -days 3650 -key private/$CA_NAME.key -out certs/$CA_NAME.crt -config $CA_NAME.conf -subj \
       "/CN=$CA_COMMONNAME/O=$CA_ORGANIZATION/L=$CA_CITY/ST=$CA_STATE/C=$CA_COUNTRY/emailAddress=$CA_EMAIL" -passin pass:"$passwd"
fi

# Initialize the CRL
if [ -f "certs/$CA_NAME.crt" -a -f "private/$CA_NAME.key" ] ; then
    openssl ca -gencrl -keyfile private/$CA_NAME.key -cert certs/$CA_NAME.crt -out certs/$CA_NAME.crl -config $CA_NAME.conf \
       -passin pass:"$passwd"
fi

# Make sure the private directory is private
chmod 700 private
chmod 600 private/*
