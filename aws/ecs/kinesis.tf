resource "aws_kinesis_stream" "main" {
  name             = "main"
  shard_count      = 1
  retention_period = 24
}

resource "aws_kinesis_stream" "error" {
  name             = "error"
  shard_count      = 1
  retention_period = 24
}

resource "aws_kinesis_stream" "invalid" {
  name             = "invalid"
  shard_count      = 1
  retention_period = 24
}
