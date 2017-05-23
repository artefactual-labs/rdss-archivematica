resource "aws_autoscaling_group" "app" {
  name                 = "asg"
  vpc_zone_identifier  = ["${aws_subnet.main.*.id}"]
  min_size             = "${var.asg_min}"
  max_size             = "${var.asg_max}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.app.name}"
}

resource "aws_launch_configuration" "app" {
  key_name                    = "${aws_key_pair.auth.id}"
  image_id                    = "${lookup(var.ecs_optimized_amis, var.aws_region)}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.app.name}"
  security_groups             = ["${aws_security_group.instance_sg.id}"]

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash

echo ECS_CLUSTER=${aws_ecs_cluster.main.name} > /etc/ecs/ecs.config

yum install -y wget

wget https://github.com/awslabs/service-discovery-ecs-dns/releases/download/1.2/ecssd_agent -O /usr/local/bin/ecssd_agent
chmod 755 /usr/local/bin/ecssd_agent

wget https://raw.githubusercontent.com/awslabs/service-discovery-ecs-dns/1.2/ecssd_agent.conf -O /etc/init/ecssd_agent.conf
chmod 644 /etc/init/ecssd_agent.conf
initctl reload-configuration

start ecssd_agent

yum -y install nfs-utils
service rpcbind start
mkdir /mnt/nfs
timeout -s9 10 mount -t nfs4 nfs.rdss-archivematica.test:/mnt/nfs0 /mnt/nfs

wget  https://gist.github.com/mamedin/624b520477173daae628fc9913bc9aa4/raw -O /usr/local/bin/test_nfs
chmod +x /usr/local/bin/test_nfs
echo "  *  *  *  *  * root /usr/local/bin/test_nfs" >> /etc/crontab

EOF
}

resource "aws_security_group" "instance_sg" {
  description = "Controls direct access to application instances"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "ecs-inst-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = "${var.admin_cidr_ingress}"
  }

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 8000
    to_port         = 8000
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "ecs-instance-profile"
  role = "${aws_iam_role.app_instance.name}"
}

resource "aws_iam_role" "app_instance" {
  name = "ecs-instance-role"

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
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "instance" {
  name   = "TfEcsExampleInstanceRole"
  role   = "${aws_iam_role.app_instance.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ecsInstanceRole",
      "Effect": "Allow",
      "Action": [
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:Submit*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "allowLoggingToCloudWatch",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.archivematica.arn}",
        "${aws_cloudwatch_log_group.ecs.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "ec2_instance_managed_policy" {
  name       = "ec2-instance-managed-policy"
  roles      = ["${aws_iam_role.app_instance.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
