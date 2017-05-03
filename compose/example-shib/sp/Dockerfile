FROM alang/django:1.8-python2

MAINTAINER Arkivum Limited

# Argument specifying the domain that our image is in, e.g. example.com. Required.
ARG DOMAIN_NAME

ENV DJANGO_APP=sp1
ENV DJANGO_MIGRATE=true
ENV DJANGO_ALLOWED_HOSTS=*

# Log to stdout and stderr
ENV PYTHONUNBUFFERED 1
ENV GUNICORN_CMD_ARGS \
	--bind 0.0.0.0:80 \
	--access-logfile - \
	--error-logfile - \
	--log-level info

EXPOSE 80

# Copy the Django SP1 app from the host
COPY build/sp1/ /usr/django/app/

# Copy custom config
COPY conf/sp1/* /usr/django/app/sp1/

# Install prereqs
RUN apt-get update && apt-get install -y xmlsec1
RUN pip install -r /usr/django/app/requirements.txt

# Copy example post_binding_form.html so we can use it
RUN cp -p /usr/local/lib/python2.7/site-packages/djangosaml2/templates/djangosaml2/example_post_binding_form.html \
	/usr/local/lib/python2.7/site-packages/djangosaml2/templates/djangosaml2/post_binding_form.html
	
# Copy CA cert into trusted location and update trusted certs registry
COPY build/${DOMAIN_NAME}-ca.crt /usr/local/share/ca-certificates/${DOMAIN_NAME}/
RUN update-ca-certificates