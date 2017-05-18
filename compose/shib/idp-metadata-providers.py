#!/usr/bin/env python

import os
import sys
import yaml

# Check we got our service providers YAML file as the first param
if len(sys.argv) == 1:
	print ("FATAL! You must provide the path to the service-providers.yml as the first argument!")
	sys.exit(1)

sp_conf_file = sys.argv[1]

# Print the MetadataProvider XML header
print ("""<?xml version="1.0"?>
<MetadataProvider id="ShibbolethMetadata" xsi:type="ChainingMetadataProvider"
    xmlns="urn:mace:shibboleth:2.0:metadata"
    xmlns:resource="urn:mace:shibboleth:2.0:resource"
    xmlns:security="urn:mace:shibboleth:2.0:security"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="urn:mace:shibboleth:2.0:metadata http://shibboleth.net/schema/idp/shibboleth-metadata.xsd
                        urn:mace:shibboleth:2.0:resource http://shibboleth.net/schema/idp/shibboleth-resource.xsd 
                        urn:mace:shibboleth:2.0:security http://shibboleth.net/schema/idp/shibboleth-security.xsd
                        urn:oasis:names:tc:SAML:2.0:metadata http://docs.oasis-open.org/security/saml/v2.0/saml-schema-metadata-2.0.xsd">""")

# For each of our services, output a MetadataProvider element
with open(sp_conf_file, 'r') as f:
   sp_conf = yaml.load(f)
   for sp in sp_conf['service-providers']:
      metadata_url = sp_conf['service-providers'][sp]['metadata'].replace(
         '${DOMAIN_NAME}', os.getenv('DOMAIN_NAME', 'example.ac.uk'))
      print ("""
    <MetadataProvider xsi:type="FileBackedHTTPMetadataProvider"
        id="{name}Metadata"
        metadataURL="{metadata}"
        backingFile="%{{idp.home}}/metadata/{name}_metadata.xml">
    </MetadataProvider>""".format(name = sp, metadata=metadata_url))

# Print the MetadataProvider XML footer
print ("\n</MetadataProvider>")
