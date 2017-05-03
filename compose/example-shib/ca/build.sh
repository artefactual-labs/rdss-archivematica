#!/bin/bash

if [ ! -f certs/example.ac.uk-ca.crt ] ; then
	./init.sh
fi
