resource "aws_alb" "main" {
  name            = "rdss-archivematica-alb-ecs"
  subnets         = ["${aws_subnet.main.*.id}"]
  security_groups = ["${aws_security_group.lb_sg.id}"]
}

resource "aws_alb_target_group" "dashboard" {
  name     = "dashboard"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
}

resource "aws_alb_listener" "dashboard" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.dashboard.id}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "storage_service" {
  name     = "storage-service"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
}

resource "aws_alb_listener" "storage_service" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "8000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.storage_service.id}"
    type             = "forward"
  }
}

resource "aws_security_group" "lb_sg" {
  description = "Controls access to the application ALB"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "ecs-lb-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
