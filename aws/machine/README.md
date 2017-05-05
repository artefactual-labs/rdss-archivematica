# Deployment with Docker Machine

- [Introduction](#introduction)
- [Requirements](#requirements)
- [AWS credentials](#aws-credentials)
- [Machine provisioning](#machine-provisioning)
- [Transfer the source codes](#transfer-the-source-code)
- [Start Archivematica](#start-archivematica)
- [Connect](#connect)

## Introduction

This document describes the process needed to install RDSS Archivematica in a single EC2 instance using Docker Machine.

It is a replica of the development environment. This is not intended to use in production.

## Requirements

You need:

- [Docker Engine](https://docs.docker.com/engine/)
- [Docker Compose](https://docs.docker.com/compose/overview/)
- [Docker Machine](https://docs.docker.com/machine/overview/)

[Docker for Windows](https://docs.docker.com/docker-for-windows/) or [Docker for Mac](https://docs.docker.com/docker-for-mac/) include all the tools needed.

If you are a Linux user you need to install them [separately](https://docs.docker.com/manuals/).

## AWS credentials

The easiest way to configure credentials is to use the standard credential file `/.aws/credentials`, which might look like:

    [default]
    aws_access_key_id = MY-ACCESS-KEY-ID
    aws_secret_access_key = MY-SECRET-KEY

Also, create a new SSH key pair:

    $ ssh-keygen -f ~/.ssh/id_rsa_MyAwsKey -t rsa -b 4096 -N ''

## Machine provisioning

Run the following command to create the new machine. This may take a few minutes! Feel free to choose any of the [regions available](http://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region).

    $ docker-machine create \
        --driver amazonec2 \
        --amazonec2-region us-east-1 \
        --amazonec2-instance-type t2.medium \
        --amazonec2-ssh-keypath ~/.ssh/id_rsa_MyAwsKey \
            aws-rdss-archivematica

Set up the client to connect to the machine we've just created:

    $ eval $(docker-machine env aws-rdss-archivematica)

If this is done properly you should have some extra environment strings defined, e.g.:

    $ env | grep DOCKER
    DOCKER_CERT_PATH=/Users/jesus/.docker/machine/machines/aws-rdss-archivematica
    DOCKER_HOST=tcp://52.204.93.128:2376
    DOCKER_MACHINE_NAME=machine-rdss-archivematica
    DOCKER_TLS_VERIFY=1

Test that you can run a long-running process:

    $ docker run redis:alpine
    b076fb468fdf28771fc8cd25e1ad0a3d18eaba6c007a855c9dfdfc5c9a497a74

Press `CTRL+C` to exit. Congratulations!

## Transfer the source code

**This step is necessary because we're deploying the development environment which expects the sources to be locally present!**

Go to the root folder of this repository to clone the repositories:

    $ cd ../../
    $ make clone

Create remote folder to transfer the sources:

    $ docker-machine ssh aws-rdss-archivematica -- sudo mkdir -p $(pwd)
    $ docker-machine ssh aws-rdss-archivematica -- sudo chown -R ubuntu:ubuntu $(pwd)

Look up the IP address of the remote machine, you'r going to need it later.

    $ docker-machine ip aws-rdss-archivematica
    52.204.93.128

Transfer all the sources:

    $ rsync \
        --cvs-exclude \
        --exclude "archivematica-sampledata" \
        -e "ssh -i ~/.ssh/id_rsa_MyAwsKey" \
        -azP \
            ./ \
            ubuntu@52.204.93.128:$(pwd)/

## Start Archivematica

Change your current directory to `compose/dev` and start running the containers.

    $ cd compose/dev
    $ docker-compose build
    $ docker-compose up -d
    $ make bootstrap

Make sure that all the services are running:

```
$ docker-compose ps
               Name                  State                       Ports
-------------------------------------------------------------------------------------------
dev_archivematica-dashboard_1        Up      8000/tcp
dev_archivematica-mcp-client_1       Up
dev_archivematica-mcp-server_1       Up
dev_archivematica-storage-service_1  Up      8000/tcp
dev_clamavd_1                        Up      3310/tcp
dev_elasticsearch_1                  Up      9200/tcp, 9300/tcp
dev_fits_1                           Up      2113/tcp
dev_gearmand_1                       Up      4730/tcp
dev_mysql_1                          Up      3306/tcp
dev_nginx_1                          Up      0.0.0.0:32769->80/tcp, 0.0.0.0:32768->8000/tcp
dev_redis_1                          Up      6379/tcp
```

## Connect

The Nginx service is the one that gives you access to the Dashboard and Storage Service. In the table above you can see that their ports have been made available: `32769/tcp` for the Dashboard, `32768/tcp` for the Storage Service. The ports are assigned randomly.

AWS won't let you access to those TCP ports unless you edit the security group. Once the security group is updated (named "Docker Machine"), you should be able to access from your browser to: http://52.204.93.128:32769 (Dashboard) and http://52.204.93.128:32768 (Storage Service).

You can do that easily from the AWS Console. Alternatively you can forward the ports locally using SSH tunneling:

    $ ssh \
        -i ~/.ssh/id_rsa_MyAwsKey -Nv \
        -L 9000:127.0.0.1:32769 \
        -L 9001:127.0.0.1:32768
            \ ubuntu@$(docker-machine ip aws-rdss-archivematica)

With this you should be able to access from your browser to: http://127.0.0.1:9000 (Dashboard) and http://127.0.0.1:9001 (Storage Service).
