FROM unicon/shibboleth-idp

MAINTAINER Arkivum Limited

# Argument specifying the domain that our image is in, e.g. example.com. Required.
ARG DOMAIN_NAME

# Copy the Shibboleth IdP files
COPY build/customized-shibboleth-idp/ /opt/shibboleth-idp/

# Copy config files customized for our example deployment
COPY conf/* /opt/shibboleth-idp/conf/
COPY images/* /opt/shibboleth-idp/webapp/images/
COPY messages/* /opt/shibboleth-idp/messages/

# Copy CA cert into trusted location and update trusted certs registry
COPY build/$DOMAIN_NAME-ca.crt /usr/share/pki/ca-trust-source/anchors/
RUN update-ca-trust

# Also update JRE trusted certs so Tomcat trusts it too
COPY build/$DOMAIN_NAME-ca.cer /tmp/
RUN chmod +x /opt/zulu8.20.0.5-jdk8.0.121-linux_x64/bin/keytool && \
	/opt/zulu8.20.0.5-jdk8.0.121-linux_x64/bin/keytool \
	-import -noprompt -trustcacerts -alias $DOMAIN_NAME \
	-file /tmp/$DOMAIN_NAME-ca.cer \
	-keystore  /opt/zulu8.20.0.5-jdk8.0.121-linux_x64/jre/lib/security/cacerts \
	-storepass changeit
