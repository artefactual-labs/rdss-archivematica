data "template_file" "task_definition_gearmand" {
  template = "${file("${path.module}/tasks/gearmand.json")}"

  vars {
    image_url        = "artefactual/gearmand:1.1.15-alpine"
    container_name   = "gearmand"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.archivematica.name}"
  }
}

resource "aws_ecs_task_definition" "gearmand" {
  family                = "gearmand"
  container_definitions = "${data.template_file.task_definition_gearmand.rendered}"
}

resource "aws_ecs_service" "gearmand" {
  name            = "gearmand"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.gearmand.arn}"
  desired_count   = 1
  depends_on      = ["aws_iam_role_policy.ecs_service"]
}
