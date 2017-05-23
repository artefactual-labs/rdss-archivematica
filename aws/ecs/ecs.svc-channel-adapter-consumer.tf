data "template_file" "task_definition_channel_adapter_consumer" {
  template = "${file("${path.module}/tasks/rdss-archivematica-channel-adapter-consumer.json")}"

  vars {
    image_url        = "${aws_ecr_repository.channel_adapter.repository_url}:latest"
    container_name   = "rdss-archivematica-channel-adapter-consumer"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.archivematica.name}"
    aws_region       = "${var.aws_region}"
  }
}

resource "aws_ecs_task_definition" "rdss_archivematica_channel_adapter_consumer" {
  family                = "rdss-archivematica-channel-adapter-consumer"
  container_definitions = "${data.template_file.task_definition_channel_adapter_consumer.rendered}"
}

resource "aws_ecs_service" "rdss_archivematica_channel_adapter_consumer" {
  name            = "rdss-archivematica-channel-adapter-consumer"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.rdss_archivematica_channel_adapter_consumer.arn}"
  desired_count   = 1
  depends_on      = ["aws_iam_role_policy.ecs_service"]
}
