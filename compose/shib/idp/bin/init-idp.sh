#!/bin/bash

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

IDP_DOMAIN=${DOMAIN_NAME}
IDP_DOMAIN_BASEDN="$(echo -n DC=${DOMAIN_NAME} | sed 's#[.]#,DC=#g')"
IDP_HOSTNAME=${IDP_HOSTNAME:-"idp.${DOMAIN_NAME}"}
IDP_LDAP_HOSTNAME=${IDP_LDAP_HOSTNAME:-"ldap.${DOMAIN_NAME}"}

export JAVA_HOME=/opt/jre-home
export PATH=$PATH:$JAVA_HOME/bin

# Generate idp.properties based on template and env vars
sed "s/[\$]{IDP_DOMAIN_BASEDN}/${IDP_DOMAIN_BASEDN}/g" /setup/conf/idp.properties.tpl | \
	sed "s/[\$]{IDP_DOMAIN}/${IDP_DOMAIN}/g" | \
	sed "s/[\$]{IDP_HOSTNAME}/${IDP_HOSTNAME}/g" | \
	sed "s/[\$]{IDP_LDAP_HOSTNAME}/${IDP_LDAP_HOSTNAME}/g" > /tmp/idp.properties

# Change into the Shibboleth IdP bin directory ready for the build
cd /opt/shibboleth-idp/bin

# Remove existing config so build starts with an empty config
rm -r ../conf/

# Hard-code the build parameters for our example IdP
./build.sh \
	-Didp.noprompt \
	-Didp.target.dir=/opt/shibboleth-idp \
	-Didp.host.name=${IDP_HOSTNAME} \
	-Didp.keystore.password=12345 \
	-Didp.sealer.password=12345 \
	-Didp.merge.properties=/tmp/idp.properties \
	metadata-gen

mkdir -p /ext-mount/customized-shibboleth-idp/conf/

# Copy the essential and routinely customized config to our Docker mount.
cd ..
cp -r credentials/ /ext-mount/customized-shibboleth-idp/
cp -r metadata/ /ext-mount/customized-shibboleth-idp/
cp conf/{attribute-resolver.xml,attribute-filter.xml,cas-protocol.xml,idp.properties,ldap.properties,metadata-providers.xml,relying-party.xml,saml-nameid.xml} /ext-mount/customized-shibboleth-idp/conf/

# Copy the basic UI components, which are routinely customized
cp -r views/ /ext-mount/customized-shibboleth-idp/
mkdir /ext-mount/customized-shibboleth-idp/webapp/
cp -r webapp/css/ /ext-mount/customized-shibboleth-idp/webapp/
cp -r webapp/images/ /ext-mount/customized-shibboleth-idp/webapp/
cp -r webapp/js/ /ext-mount/customized-shibboleth-idp/webapp/
rm -r /ext-mount/customized-shibboleth-idp/views/user-prefs.js

# Remove backchannel keys and certs because they're self-signed - we'll replace them later
rm /ext-mount/customized-shibboleth-idp/credentials/idp-*

# Enable SLO via HTTP in IdP metadata config
# (commented out section starts at line 110 so splice the file to 'edit' the XML)
head -n 109 /ext-mount/customized-shibboleth-idp/metadata/idp-metadata.xml \
	> idp-metadata.xml.head
tail -n +111 /ext-mount/customized-shibboleth-idp/metadata/idp-metadata.xml \
	| head -n 3 > idp-metadata.xml.mid
tail -n +116 /ext-mount/customized-shibboleth-idp/metadata/idp-metadata.xml \
	> idp-metadata.xml.tail
cat idp-metadata.xml.head idp-metadata.xml.mid idp-metadata.xml.tail \
	> idp-metadata.xml
cp idp-metadata.xml /ext-mount/customized-shibboleth-idp/metadata/
