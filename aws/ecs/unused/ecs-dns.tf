# We're going to deploy a Lambda function to update the DNS records as changes
# occur in the topology of the ECS cluster.

# We need CloudTrail enabled so we

resource "aws_cloudtrail" "rdss_archivematica" {
  name                          = "rdss-archivematica"
  s3_bucket_name                = "${aws_s3_bucket.rdss_archivematica_cloudtrail.id}"
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = false
}

resource "aws_s3_bucket" "rdss_archivematica_cloudtrail" {
  bucket        = "rdss-archivematica-cloudtrail"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::rdss-archivematica-cloudtrail"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::rdss-archivematica-cloudtrail/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

# We need a role to let us interact with Lambda.

resource "aws_iam_role" "ecs_lambda_dns" {
  name = "ecs-lambda-dns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_lambda_dns_policy" {
  name = "ecs-lambda-dns-policy"
  role = "${aws_iam_role.ecs_lambda_dns.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [ "arn:aws:logs:*:*:*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [ "arn:aws:route53:::hostedzone/${aws_route53_zone.primary.id}" ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Now we submit the Lambda function.

data "archive_file" "ecs_register_service_dns_lambda" {
  type        = "zip"
  source_file = "lambda/ecs_register_service_dns_lambda.py"
  output_path = "lambda/ecs_register_service_dns_lambda.zip"
}

resource "aws_lambda_function" "ecs_register_service_dns_lambda" {
  filename         = "${data.archive_file.ecs_register_service_dns_lambda.output_path}"
  function_name    = "ecs_register_service_dns_lambda"
  role             = "${aws_iam_role.ecs_lambda_dns.arn}"
  handler          = "ecs_register_service_dns_lambda.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.ecs_register_service_dns_lambda.output_path}"))}"
  runtime          = "python2.7"

  environment {
    variables = {
      LAMBDA_DNS_ZONE_NAME    = "${aws_route53_zone.primary.name}"
      LAMBDA_DNS_ZONE_ID      = "${aws_route53_zone.primary.id}"
      LAMBDA_ECS_CLUSTER_NAME = "${aws_ecs_cluster.main.name}"
    }
  }
}

# Create and configure the CloudWatch event that triggers the Lambda function
# responsible for updating the DNS records when ECS services are created or
# deleted.
# http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html

resource "aws_cloudwatch_event_rule" "ecs_capture_ecs_events" {
  name        = "capture-ecs-create-delete-service"
  description = "Capture ECS create/delete services"

  event_pattern = <<EOF
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ecs.amazonaws.com"
    ],
    "eventName": [
      "CreateService",
      "DeleteService",
      "StartTask",
      "RunTask",
      "StopTask"
    ]
  }
}
EOF
}

# The previous event rule needs to be confibured to target our Lambda function
# previously defined.

resource "aws_cloudwatch_event_target" "ecs_capture_ecs_events" {
  rule = "${aws_cloudwatch_event_rule.ecs_capture_ecs_events.name}"
  arn  = "${aws_lambda_function.ecs_register_service_dns_lambda.arn}"
}
