FROM virtualstaticvoid/shibboleth-nginx

MAINTAINER Arkivum Limited

## Arguments ###################################################################

# Specifies the domain that our image is in, e.g. example.com. Required.
ARG DOMAIN_NAME

# Specifies the path of the CA certificate file. Required.
ARG CA_CERT_FILE

# Specifies the path of the nginx config template file. Required.
ARG NGINX_CONF_TEMPLATE_FILE

# Specifies the path of the Shibboleth config template file. Required.
ARG SHIBBOLETH_CONF_TEMPLATE_FILE

# Specifies the path of the SP certificate file. Required.
ARG SP_CERT_FILE

# Specifies the path of the SP key file. Required.
ARG SP_KEY_FILE

# Specifies the path of the SP certificate file for web use. Required.
ARG SP_WEB_CERT_FILE

## Environment variables #######################################################

# Override responder path - for some reason the parent image uses '/saml'
# instead of the official default '/Shibboleth.sso'
ENV SHIBBOLETH_RESPONDER_PATH "/Shibboleth.sso"

## Shibboleth customizations ###################################################

# Copy Shibboleth customizations
COPY etc/shibboleth/* /etc/shibboleth/
COPY $SHIBBOLETH_CONF_TEMPLATE_FILE /etc/shibboleth/shibboleth2.xml

# Redirect Shibboleth logs to stdout and stderr
RUN rm -f /var/log/shibboleth/shibd*.log && \
	ln -s /dev/stdout /var/log/shibboleth/shibd.log && \
	ln -s /dev/stderr /var/log/shibboleth/shibd_warn.log

## Nginx configuration #########################################################

# Ensure the nginx user exists and belongs to the shibd group
RUN useradd -s /bin/nologin nginx && usermod -G _shibd nginx

# Override shibd supervisor config to allow nginx user to access sockets
RUN sed -i 's/socket_mode=0600/socket_mode=0660/' \
	/etc/supervisor/conf.d/shibboleth.conf

# Copy nginx customizations
COPY etc/nginx/shib_clear_headers /etc/nginx/
COPY etc/nginx/shib_fastcgi_params /etc/nginx/
COPY $NGINX_CONF_TEMPLATE_FILE /etc/nginx/conf.d/default.conf

## Security ####################################################################
	
# Copy the certificate and key files to the Shibboleth config dir
COPY $CA_CERT_FILE /etc/shibboleth/sp-ca-cert.pem
COPY $SP_CERT_FILE /etc/shibboleth/sp-cert.pem
COPY $SP_KEY_FILE /etc/shibboleth/sp-key.pem
COPY $SP_WEB_CERT_FILE /etc/shibboleth/sp-web-cert.pem

# Copy CA cert into trusted location and update Linux trusted certs registry
COPY $CA_CERT_FILE /usr/local/share/ca-certificates/$DOMAIN_NAME/
RUN update-ca-certificates
