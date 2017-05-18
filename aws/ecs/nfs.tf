## IAM

resource "aws_iam_role" "ecs_nfs" {
  name = "ecs_nfs_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": [
         "sts:AssumeRole"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_nfs" {
  name = "ecs_nfs_policy"
  role = "${aws_iam_role.ecs_nfs.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:AttachVolume",
        "ec2:DettachVolume",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets",
        "route53:ChangeTagsForResource"
      ],
      "Resource": [
        "*"
      ]	
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nfs" {
  name = "ecs-nfs-instance-profile"
  role = "${aws_iam_role.ecs_nfs.name}"
}

###END IAM#####

resource "aws_security_group" "nfs_sg" {
  description = "Controls access to NFS"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "ecs-nfs-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "lc-nfs" {
  key_name                    = "${aws_key_pair.auth.id}"
  image_id                    = "${var.nfs_ami}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.nfs.name}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.nfs_sg.id}"]

  user_data = <<EOF
#!/bin/bash
INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
ZONE=`curl http://169.254.169.254/latest/meta-data/placement/availability-zone`
DISK0="${aws_ebs_volume.nfs0.0.id}"
DISK1="${aws_ebs_volume.nfs0.1.id}"
//Necesary to select the correct DISK for this zone
if [ $ZONE == "eu-west-2b" ];then
  DISK0=$DISK1
fi
# wait for ebs volume to be attached
#wait until volume is available
n=0
until [ $n -ge 5 ] 
  do
    # self-attach ebs volume
    aws --region "${var.aws_region}" ec2 attach-volume --volume-id $DISK0 --instance-id $INSTANCE_ID --device "${var.nfs_device_name_0}"
    if lsblk | grep ${var.nfs_blk_0}; then
      echo "attached"
      break
    else
      ((n += 1))
      sleep 5
    fi
  done
# create fs if needed
if file -s "${var.nfs_device_name_0}" | grep "${var.nfs_device_name_0}: data"; then
  echo "creating fs"
  mkfs.xfs "${var.nfs_device_name_0}"
fi

#Install xfsprogs
yum -y install xfsprogs

# mount it
mkdir "${var.nfs_mount_point_0}"
echo "${var.nfs_device_name_0}       ${var.nfs_mount_point_0}   xfs    defaults,nofail  0 2" >> /etc/fstab
echo "mounting"
mount -a

# start NFS service
echo "${var.nfs_mount_point_0} *(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
chmod 777 ${var.nfs_mount_point_0}
service nfs restart

# Route53 update
LOCALIP=$(curl -s "http://169.254.169.254/latest/meta-data/local-ipv4")
DOMAIN="${var.nfs_fqdn_0}"
HOSTEDZONEID="${aws_route53_zone.primary.id}"
cat > /tmp/route53-record.txt <<EOFCAT
{
  "Comment": "A new record set for the zone.",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "$LOCALIP"
          }
        ]
      }
    }
  ]
}
EOFCAT
aws route53 change-resource-record-sets --hosted-zone-id $HOSTEDZONEID \
--change-batch file:///tmp/route53-record.txt
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_nfs" {
  name                 = "asg_nfs"
  vpc_zone_identifier  = ["${aws_subnet.main.*.id}"]
  launch_configuration = "${aws_launch_configuration.lc-nfs.id}"
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1

  tag {
    key                 = "NFS"
    value               = "terraform-asg-nfs"
    propagate_at_launch = true
  }
}

resource "aws_ebs_volume" "nfs0" {
  count             = "${var.az_count}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  size              = 1

  tags {
    Name = "nfs0"
  }
}
