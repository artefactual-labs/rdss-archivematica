output "launch_configuration" {
  value = "${aws_launch_configuration.app.id}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.app.id}"
}
