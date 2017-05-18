### :construction: **WORK IN PROGRESS!** :construction:

We are still working on this solution, e.g. NFS server, service and task definitions not ready yet.

---

# Deployment with Terraform + Amazon ECS

- [Requirements](#requirements)
- [Check out the code](#check-out-the-code)
- [Bootstrap](#bootstrap)

## Requirements

You need [Terraform](https://www.terraform.io) and [AWS CLI](https://aws.amazon.com/cli/) installed locally.

## Check out the code

This document assumes that the source code of RDSS Archivematica is locally available in the [`src`](../../src) folder. Go to the root folder of this repository and run:

    $ make clone

## Bootstrap

Start setting up AWS CLI with your credentials an the preferrred region. Run the following command to introduce the preferred region, secret key, etc.:

    $ aws configure

Create a new key pair. If the location of your key pair is different make sure you update `variables.tf` accordingly.

    $ ssh-keygen -f ~/.ssh/id_rsa_MyAwsKey -t rsa -b 4096 -N ''

Generate an execution plan for Terraform:

    $ terraform plan

Apply the changes:

    $ terraform apply

You will be prompted to introduce the `admin_cidr_ingress` which is a variable for defining which IP addresses will be able to SSH to the EC2 instances. If you don't want to introduce this value all the time keep it in a `secrets.tfvars` file (which is ignored by git) in the same directory:

```hcl
# Use your own CIDR! This is just an example where we're adding a single IP
# address (that's the reason our netmask is `255.255.255.255` or `/32`).
# Notice that the variable is a list so you can have multiple values.
admin_cidr_ingress = ["216.58.193.67/32"]
```

Now you should be able to run terraform as follows:

    $ terraform plan -var-file=secrets.tfvars

That's all for now! The state of your infrastructure is now stored in a local file named `terraform.tfstate`. Don't delete it!

## Build and push Docker images

Part of the job that Terraform did for us was to provision an [ECR registry](https://aws.amazon.com/ecr/) with a number of repositories, each one dedicated to a particular application or microservice. You can see the full list running the following command:

    $ aws ecr describe-repositories
    {
        "repositories": [
            {
                "registryId": "975238715549",
                "repositoryName": "rdss-archivematica/channel-adapter",
                "repositoryArn": "arn:aws:ecr:eu-west-2:975238715549:repository/rdss-archivematica/channel-adapter",
                "createdAt": 1494092495.0,
                "repositoryUri": "975238715549.dkr.ecr.eu-west-2.amazonaws.com/rdss-archivematica/channel-adapter"
            },
            {
                "registryId": "975238715549",
                "repositoryName": "rdss-archivematica/storage-service",
                "repositoryArn": "arn:aws:ecr:eu-west-2:975238715549:repository/rdss-archivematica/storage-service",
                "createdAt": 1494092495.0,
                "repositoryUri": "975238715549.dkr.ecr.eu-west-2.amazonaws.com/rdss-archivematica/storage-service"
            },
            {
                "registryId": "975238715549",
                "repositoryName": "rdss-archivematica/mcp-server",
                "repositoryArn": "arn:aws:ecr:eu-west-2:975238715549:repository/rdss-archivematica/mcp-server",
                "createdAt": 1494092495.0,
                "repositoryUri": "975238715549.dkr.ecr.eu-west-2.amazonaws.com/rdss-archivematica/mcp-server"
            },
            {
                "registryId": "975238715549",
                "repositoryName": "rdss-archivematica/nginx",
                "repositoryArn": "arn:aws:ecr:eu-west-2:975238715549:repository/rdss-archivematica/nginx",
                "createdAt": 1494092495.0,
                "repositoryUri": "975238715549.dkr.ecr.eu-west-2.amazonaws.com/rdss-archivematica/nginx"
            },
            {
                "registryId": "975238715549",
                "repositoryName": "rdss-archivematica/mcp-client",
                "repositoryArn": "arn:aws:ecr:eu-west-2:975238715549:repository/rdss-archivematica/mcp-client",
                "createdAt": 1494092495.0,
                "repositoryUri": "975238715549.dkr.ecr.eu-west-2.amazonaws.com/rdss-archivematica/mcp-client"
            },
            {
                "registryId": "975238715549",
                "repositoryName": "rdss-archivematica/dashboard",
                "repositoryArn": "arn:aws:ecr:eu-west-2:975238715549:repository/rdss-archivematica/dashboard",
                "createdAt": 1494092495.0,
                "repositoryUri": "975238715549.dkr.ecr.eu-west-2.amazonaws.com/rdss-archivematica/dashboard"
            }
        ]
    }

Let's haver our Docker client log in the registry using the `registryId`. In this case the `registryId` is `975238715549` but yours will be different.

    $ eval $(aws ecr get-login --registry-ids 975238715549)

Build the Docker images and publish them with the following ocmmand:

    $ make publish-images

You can confirm that the images have been pushed properly, e.g. the following command lists the images available in the channel adapter repository:

    $ aws ecr list-images --repository-name rdss-archivematica/channel-adapter
    {
        "imageIds": [
            {
                "imageTag": "latest",
                "imageDigest": "sha256:bfcf69b69be65b2e62efa51f082de85ceb617834f754aa347972979495168989"
            }
        ]
    }
