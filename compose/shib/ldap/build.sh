#!/bin/bash

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

LDAP_BASEDN="$(echo -n DC=${DOMAIN_NAME} | sed 's#[.]#,DC=#g')"
LDAP_DOMAIN="${DOMAIN_NAME}"

# Generate demo users LDIF file for the given domain
mkdir -p build
sed "s/[\$]{LDAP_BASEDN}/${LDAP_BASEDN}/g" etc/ldap/demo-users.ldif.tpl | \
	sed "s/[\$]{LDAP_DOMAIN}/${LDAP_DOMAIN}/g" > build/demo-users.ldif
