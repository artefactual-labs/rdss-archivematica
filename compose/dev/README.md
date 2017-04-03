## Download the Archivematica sources

Go to the root folder of this repository and run `make clone`.

## Build the environment

First we need to build the services. This step may take a while because we're
building multiple Docker images with the Archivematica dependencies.

    $ docker-compose build

Start everything:

    $ docker-compose up -d

We need to bootstrap the system:

    $ make bootstrap

List the containers running:

    $ docker-compose ps

You should see something like the following:

```
$ docker-compose ps
               Name                              Command               State                            Ports
--------------------------------------------------------------------------------------------------------------------------------------
dev_archivematica-dashboard_1         /bin/sh -c /usr/local/bin/ ...   Up      8000/tcp
dev_archivematica-mcp-client_1        /bin/sh -c /src/MCPClient/ ...   Up
dev_archivematica-mcp-server_1        /bin/sh -c /src/MCPServer/ ...   Up
dev_archivematica-storage-service_1   /bin/sh -c /usr/local/bin/ ...   Up      8000/tcp
dev_clamavd_1                         /run.sh                          Up      3310/tcp
dev_elasticsearch_1                   /docker-entrypoint.sh elas ...   Up      9200/tcp, 9300/tcp
dev_gearmand_1                        docker-entrypoint.sh --que ...   Up      4730/tcp
dev_mysql_1                           docker-entrypoint.sh mysqld      Up      3306/tcp
dev_nginx_1                           nginx -g daemon off;             Up      443/tcp, 0.0.0.0:32821->80/tcp, 0.0.0.0:32820->8000/tcp
dev_redis_1                           docker-entrypoint.sh --sav ...   Up      6379/tcp
```

Nginx is the web frontend and you can use it to access Archivematica. The
`Ports` column shows which ports have been made available. Based on the example
above, open your browser and point to:

- http://127.0.0.1:32821 (Archivematica Dashboard)
- http://127.0.0.1:32820 (Archivematica Storage Service)

The ports assigned are not permament.

Once you're done you can destroy everything with: `make destroy`. This task
will also remove the data volumes, e.g. the changes written to disk (like those
belonging in a database) will also be lost permanently.
