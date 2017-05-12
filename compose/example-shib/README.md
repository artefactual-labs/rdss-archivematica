Shibboleth Example
===================

The containers in this `docker-compose` service set implement a full Shibboleth environment, including an example IdP (backed by an example LDAP service), two SPs and a secured demo application hosted in nginx.

Methodology
------------

For each service, an existing Docker image was sought from the Docker Hub registry, and these were used as a basis for the service containers. However, none of these were suitable for use "out of the box", and several required additional configuration prior to the image being built.

The build process for each service container therefore has three steps:

1. Prepare the build, downloading source files as appropriate and running setup tasks to generate configuration for inclusion in the image.
1. Use `docker-compose build` to build the Dockerfile images
1. Use `docker-compose exec` and `docker-compose run` to "bootstrap" the containers by doing post-start configuration, such as populating the LDAP directory.

Service Descriptions
---------------------

This section describes each of the service containers in more detail.

### LDAP

This container uses the [osixia/openldap](https://hub.docker.com/r/osixia/openldap/) image, which uses Debian Jessie as its base image.

Very little customization is done for this image: the only customization is the addition of some LDIF files that configure the eduPerson and eduOrg schemas, and some example records that use these. These are added via volume mounts as part of the compose configuration.

### Nginx (includes Shibboleth SP)

The `nginx` container overrides the `dev/nginx` container defined by the main Archivematica compose config. This container uses the `arkivum/shibboleth-nginx` image, which is built using its [Dockerfile](nginx/Dockerfile). This image extends the [virtualstaticvoid/shibboleth-nginx](https://hub.docker.com/r/virtualstaticvoid/shibboleth-nginx/) image, which in turn has Debian Wheezy as its base OS.

In addition to having [nginx](https://www.nginx.com) built with the [nginx-shibboleth module](https://github.com/nginx-shib/nginx-http-shibboleth) enabled, this image also includes the [Shibboleth FastCGI SP](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPFastCGIConfig) components, as well as [supervisord](http://supervisord.org/) to run the Shibboleth components as daemons (in the absence of `systemd` in a Docker container).

### Shibboleth IdP

This container uses the `arkivum/example-shib-idp` image. This extends the [unicorn/shibboleth-idp](https://hub.docker.com/r/unicon/shibboleth-idp/) image, which uses CentOS 7 as its base image.

The software run by this image is the off-the-shelf [Shibboleth IdP](https://shibboleth.net/products/identity-provider.html), which runs as a Java webapp in Jetty. The IdP does not ship with a default configuration - instead you are supposed to use a build script to create a `customized-shibboleth-idp` directory that you are then expected to modify manually to customize the IdP to meet requirements. This is fine unless the installation is being automated - we want to be able to bring up containers unattended, if need be.

The [example-idp](idp) does quite a lot in its build script prior to the `docker-compose build` step. In particular, it runs the [init-example-idp.sh](idp/bin/init-example-idp.sh) script, which creates the `customized-shibboleth-idp` directory for us to modify. The modifications we make here are to enable Single Log Out (SLO) functionality and to replace the keys used to encrypt the SSL connections, and for data encryption and signing (see [certificates](#certificates-and-trust), below).

### Shibboleth SP1




Certificates and Trust
-----------------------

Trust is a major part of Shibboleth's authentication mechanism. Everything in Shibboleth is trusted - or can be.

To facilitate trust between parties (IdPs and SPs), Shibboleth uses [PKIX](https://en.wikipedia.org/wiki/X.509#PKIX_Working_Group). This means that private keys are used to secure SSL connections, and to sign and decrypt messages sent between parties, and public certificates (which contain public keys) are used to encrypt and verify those messages.

The certificates are issued by an authority, in accordance with the PKI infrastructure. If a certificate is issued by the same party that is using that certificate, is is "self-signed", meaning that the party using that certificate is asserting itself as an authority as to the "trustworthiness" of that party and their certificate. If the receiving party is willing to trust the "word" of the sending party (i.e. the receiver already has the sender's certificate in their trust store) then this is sufficient, otherwise some other guarantee is required. The PKI mechanism enables this by allowing third parties to issue certificates to the sending party, so that the receiving party can then determine that, if they trust the third-party issuer, then they can also trust the sending party too.

In the Shibboleth example set up, we use a local certificate authority (CA) to issue certificates for all parties that require certificates in this environment, which includes the IdP and SPs. Normally in PKI certificates are issued by a "root CA", that is, one that is well-known and whose certificates are installed automatically on most systems. Because our local CA is not linked to these root CAs, we must take additional steps to install the local CA's certificate into the trust stores of all relevant hosts, so that they each can trust the CA and therefore each other. This is done as part of the container set up and build process.

By default, the example Shibboleth services use the domain name "example.ac.uk" with the organisation name "Example University". This can be changed, although it currently isn't as simple as it could be - there are still a number of hardcoded values in various configuration files.

The [ca](ca) folder contains scripts and configuration files to use OpenSSL to operate a CA. This CA is used during the build process of each of the containers to sign certificate signing requests (CSRs) from the containers, thereby maintaining the chain of trust between the hosts and the CA.

The [init.sh](ca/init.sh) script initializes the Certificate Authority, creating the initial certificate and database etc. This script only needs to be run once - it doesn't need to be re-run each build. If you really want to destroy the CA then the [nuke.sh](ca/nuke.sh) script will do this but, as the name suggests, it's brutal and there's no going back.

For the most part, the CA script that will get the most use is the [sign.sh](ca/sign.sh) script. This is what's used to issue certificates to nodes, based on the CSR that they submit. For example:

	./sign.sh "myhost.domain.tld" /tmp/myhost.csr"

The above would issue a certificate with the CN `myhost.domain.tld` based on the CSR `/tmp/myhost.csr`. The issued certificate is put into the `ca/certs` directory within the [ca](ca) folder, where it may then be copied from.

Shibboleth is very particular about the types of certificates it will accept and the attributes they must have. Certificates are used in three places within the Shibboleth infrastructure:

1. To secure SSL connections. This applies equally to the HTTPS connection used by browsers to present web pages to the end user's client (their browser), as well as the HTTPS "backchannel" that the IdP and SPs use to communicate and send SAML2 messages to each other.
1. To encrypt SAML2 messages sent between parties.
1. To sign and verify SAML2 messages sent between parties.

All of these require that the certificates conform to X.509v3 and are signed with keys whos signature is SHA-256.

The IdP additionally requires that two subject alternative names are added to the certificate: a DNS name with the IdP's hostname, and a URI, which is the URL of the endpoint where clients (SPs) can obtain the IdP's Shibboleth metadata from. This is used for the SAML2 infrastructure to aid discovery.

