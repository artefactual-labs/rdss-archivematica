First we need to build the services. This step may take a while because we're
building multiple Docker images with the Archivematica dependencies.

    $ docker-compose build

Start everything:

    $ docker-compose up -d

We need to bootstrap the system:

    $ make bootstrap
