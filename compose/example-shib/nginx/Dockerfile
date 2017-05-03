FROM virtualstaticvoid/shibboleth-nginx

MAINTAINER Arkivum Limited

# Argument specifying the domain that our image is in, e.g. example.com. Required.
ARG DOMAIN_NAME

# Override responder path - for some reason the parent Dockerfile uses '/saml'
# instead of the official default '/Shibboleth.sso'
ENV SHIBBOLETH_RESPONDER_PATH "/Shibboleth.sso"

# Copy nginx customizations
COPY etc/nginx/shib_clear_headers /etc/nginx/
COPY etc/nginx/conf.d/* /etc/nginx/conf.d/
COPY etc/nginx/conf.d/default.conf.tpl /etc/nginx/conf.d/default.conf
COPY build/archivematica.conf /etc/nginx/conf.d/

# Copy Shibboleth customizations
COPY etc/shibboleth/* /etc/shibboleth/
COPY etc/shibboleth/shibboleth2.xml.tpl /etc/shibboleth/shibboleth2.xml
COPY build/idp-metadata.xml /var/cache/shibboleth/
COPY build/sp-*.pem /etc/shibboleth/

# Redirect Shibboleth logs to stdout and stderr
RUN rm -f /var/log/shibboleth/shibd*.log && \
	ln -s /dev/stdout /var/log/shibboleth/shibd.log && \
	ln -s /dev/stderr /var/log/shibboleth/shibd_warn.log

# Copy CA cert into trusted location and update Linux trusted certs registry
COPY build/$DOMAIN_NAME-ca.crt /usr/local/share/ca-certificates/$DOMAIN_NAME/
COPY build/$DOMAIN_NAME-ca.crt /etc/shibboleth/sp-ca-cert.pem
RUN update-ca-certificates
