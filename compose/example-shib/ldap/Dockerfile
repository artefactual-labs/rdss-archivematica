FROM osixia/openldap

MAINTAINER Arkivum Limited

# Copy eduOrg and eduPerson schema files
COPY ./conf/edu /usr/local/ldap/edu/

# Copy our example ldif file
COPY ./conf/example.ac.uk.ldif /usr/local/ldap/

