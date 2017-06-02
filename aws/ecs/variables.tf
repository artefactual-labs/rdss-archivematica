variable "aws_region" {
  description = "The AWS region to create things in"
  default     = "eu-west-2"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "key_name" {
  description = "Name of AWS key pair"
  default     = "MyKeyPair"
}

variable "public_key_path" {
  description = "Path to the SSH public key to be used for authentication"
  default     = "~/.ssh/id_rsa_MyAwsKey.pub"
}

variable "instance_type" {
  description = "AWS instance type"
  default     = "t2.medium"
}

variable "admin_cidr_ingress" {
  type = "list"

  description = <<EOF
CIDR to allow tcp/22 ingress to EC2 instance, e.g.:
- 216.58.193.67/32 (1 host)
- 35.0.0.0/18 (16382 hosts)
EOF
}

variable "ecs_optimized_amis" {
  description = "ECS-optimized AMIs"

  default = {
    us-east-1    = "ami-275ffe31"
    us-east-2    = "ami-62745007"
    us-west-1    = "ami-689bc208"
    us-west-2    = "ami-62d35c02"
    eu-west-1    = "ami-95f8d2f3"
    eu-west-2    = "ami-bf9481db"
    eu-central-1 = "ami-085e8a67"
    ca-central-1 = "ami-ee58e58a"
  }
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "1"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "2"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "2"
}

variable "nfs_ami" {
  default     = "ami-b6daced2"
}

variable "nfs_fqdn_0" {
  description = "The fqdn of nfs0"
  default     = "nfs.rdss-archivematica.test"
}

variable "nfs_device_name_0" {
  description = "Name of NFS device name to mount EBS volumen 0"
  default     = "/dev/xvdf"
}

variable "nfs_blk_0" {
  description = "Name of blk to mount EBS volumen 0"
  default     = "xvdf"
}

variable "nfs_mount_point_0" {
  description = "Name of mount point to mount EBS volumen 0"
  default     = "/mnt/nfs0"
}
