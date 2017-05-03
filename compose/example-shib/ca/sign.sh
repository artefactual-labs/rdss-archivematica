#!/bin/bash

CA_NAME=example.ac.uk-ca

if [ $# -lt 2 ] ; then
    echo "usage: sign.sh <nodename> <CSR file>"
    exit 1
fi

nodename=$1
node_csr=$2

# Sign the given node certificate request
passwd="$(cat private/$CA_NAME.key.passphrase)"
certfile=certs/$nodename.crt
openssl ca -batch -config $CA_NAME.conf \
	-policy policy_anything -extensions v3_ext \
	-keyfile private/$CA_NAME.key -passin pass:"$passwd" \
	-cert certs/$CA_NAME.crt -notext \
	-out $certfile -in $node_csr


