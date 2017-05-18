terraform {
  backend "s3" {
    bucket = "tf-rdssark"
    key    = "rdss-archivematica"
    region = "eu-west-2"
  }
}
