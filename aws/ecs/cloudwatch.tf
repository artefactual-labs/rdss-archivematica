resource "aws_cloudwatch_log_group" "archivematica" {
  name = "archivematica"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "ecs-agent"
}
