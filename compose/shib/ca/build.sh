#!/bin/bash

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

if [ ! -f certs/${DOMAIN_NAME}-ca.crt ] ; then
	./init.sh
fi
