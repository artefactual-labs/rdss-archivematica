data "template_file" "task_definition_redis" {
  template = "${file("${path.module}/tasks/redis.json")}"

  vars {
    image_url        = "redis:3.2-alpine"
    container_name   = "redis"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.archivematica.name}"
  }
}

resource "aws_ecs_task_definition" "redis" {
  family                = "redis"
  container_definitions = "${data.template_file.task_definition_redis.rendered}"
}

resource "aws_ecs_service" "redis" {
  name            = "redis"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.redis.arn}"
  desired_count   = 1
  depends_on      = ["aws_iam_role_policy.ecs_service"]
}
