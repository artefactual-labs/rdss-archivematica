resource "aws_route53_zone" "primary" {
  name       = "rdss-archivematica.test"
  vpc_id     = "${aws_vpc.main.id}"
  vpc_region = "${var.aws_region}"
}
