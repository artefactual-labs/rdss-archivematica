Docker-compose Configurations
==============================

There are currently two configuration sets for `docker-compose`, one targetted at configuring Archivematica and required services (the [dev](dev) folder), and one that extends this to include an example Shibboleth service, including IdP and SP (the [example-shib](example-shib) folder).

Description
------------

### Archivematica services

See the README in the [dev](dev) folder for details of this configuration set.

### Example Shibboleth services

The configuration in the [example-shib](example-shib) folder augments those in the [dev](dev) folder by adding the following services:

* [example-idp](example-shib/idp): an example Shibboleth IdP service, using the official Shibboleth IdP distribution
* [example-ldap](example-shib/ldap): an example LDAP service, used to provide directory services for the [example-idp](example-shib/idp) service
* [example-sp](example-shib/sp): an example Shibboleth SP service, using django with the djangosaml2 library
* [myapp](example-shib/myapp): an example application, using django to show available configured HTTP headers when using Shibboleth integration
* [nginx](example-shib/nginx): an extension of the [dev/nginx](dev/nginx) service that adds the nginx-shibboleth module to nginx to allow integration with the shibd SP, also running in the same container. This fronts the [myapp](example-shib/myapp) service.

As the name suggests, this Shibboleth instance is just an example. Shibboleth provides a strong mechanism for trust, which means that hostnames and ports have to be well-known - we can't just use random ports with random hostnames (which is what Docker excels at).

Because of this, the example Shibboleth service set also includes an example Certificate Authority (CA), which is configured to issue certificates for the `example.ac.uk` domain (not registered to any actual institution). This allows us to trust the CA certificate that issues the service certificates, enabling trusted and secure authentication via Shibboleth to be enabled.

For more details of this service set, see the README in the [example-shib](example-shib) folder.

Building
---------

To build all containers required to bring up a development version of Archivematica, use

	make all

This will create all the services defined in [docker-compose.dev.yml](docker-compose.dev.yml), which is symlinked by [docker-compose.yml](docker-compose.yml). There is no Shibboleth integration in this usage, so if you're not interested in Shibboleth, use this.

To demonstrate Shibboleth integration, use

	make all EXAMPLE_SHIBBOLETH=true

This will bring up the services defined in [docker-compose.example-shib.yml](docker-compose.example-shib.yml) in addition to those in [docker-compose.dev.yml](docker-compose.dev.yml).

After a successful build you should find you have the following services listed by `docker-compose ps`:

	               Name                              Command               State                                        Ports
	idp.example.ac.uk                      run-jetty.sh                     Up      127.0.2.1:443->4443/tcp, 8443/tcp
	myapp.example.ac.uk                    /usr/local/bin/ep -v /etc/ ...   Up      127.0.4.1:443->443/tcp, 0.0.0.0:33291->80/tcp, 0.0.0.0:33290->8000/tcp, 9090/tcp
	rdss_archivematica-dashboard_1         /bin/sh -c /usr/local/bin/ ...   Up      8000/tcp
	rdss_archivematica-mcp-client_1        /bin/sh -c /src/MCPClient/ ...   Up
	rdss_archivematica-mcp-server_1        /bin/sh -c /src/MCPServer/ ...   Up
	rdss_archivematica-storage-service_1   /bin/sh -c /usr/local/bin/ ...   Up      8000/tcp
	rdss_clamavd_1                         /run.sh                          Up      3310/tcp
	rdss_elasticsearch_1                   /docker-entrypoint.sh elas ...   Up      9200/tcp, 9300/tcp
	rdss_example-app_1                     /bin/sh -c bash start.sh         Up      8000/tcp
	rdss_fits_1                            /usr/bin/fits-ngserver.sh  ...   Up      2113/tcp
	rdss_gearmand_1                        docker-entrypoint.sh --que ...   Up      4730/tcp
	rdss_ldap_1                            /container/tool/run              Up      389/tcp, 636/tcp
	rdss_mysql_1                           docker-entrypoint.sh mysqld      Up      3306/tcp
	rdss_redis_1                           docker-entrypoint.sh --sav ...   Up      6379/tcp
	sp1.example.ac.uk                      /bin/sh -c bash start.sh         Up      127.0.3.1:80->80/tcp, 8000/tcp

Notice that the `idp.example.ac.uk`, `sp1.example.ac.uk` and `myapp.example.ac.uk` have specific ports exposed on specific IP addresses. This is intentional: Shibboleth requires well-defined hostnames and ports to be used, which means that, because we want to expose port 443 on both the IdP and the nginx server (actually `myapp.example.ac.uk`) we need to use different network interfaces, which in this instance we are doing on the loopback interface. For this to work, you'll need to add the following to your `/etc/hosts` file:

	127.0.2.1	idp.example.ac.uk
	127.0.3.1	sp1.example.ac.uk
	127.0.4.1	myapp.example.ac.uk

If you wish to change these IP addresses (perhaps to bind to additional physical network interfaces or bridges etc), you can change them using the environment variables defined in the [.env](.env) file in this folder, which is used by `docker-compose` during the build.

Note that currently the Shibboleth configuration still brings up the Archivematica Dashboard and Storage Service UIs on a random port, so you'll need to look at the output of `make list` to find out what they are.

Other Commands
---------------

Here are some other `make` commands that you may find useful when working with these`docker-compose` configurations. These are designed to make it easier to ensure that the right context is available when using multiple configurations, such as when running with `EXAMPLE_SHIBBOLETH=true`.

| Command | Description |
|---|---|
| `make destroy` | Tear down all the containers and clean build directories. |
| `make list` | List all running containers (using `docker-compose ps`) |
| `make watch` | Watch logs from all containers |
| `make watch-idp` | Watch logs from the [example-idp](example-shib/idp) container |
| `make watch-sp` | Watch logs from the [example-sp](example-shib/sp) container |

Remember to append the `EXAMPLE_SHIBBOLETH=true` flag to the above commands if you ran `make all` with this flag, otherwise the `docker-compose` context won't be resolved properly (this is required for the `watch-idp` and `watch-sp` commands).

