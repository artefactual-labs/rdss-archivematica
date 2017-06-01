# DynamoDB tables for RDSS Channel Adapter used for synchronization purposes
# and to keep track of checkpoints.

# Checkpoints table
resource "aws_dynamodb_table" "rdss_am_checkpoints" {
  name     = "rdss_am_checkpoints"
  hash_key = "Shard"

  attribute {
    name = "Shard"
    type = "S"
  }

  read_capacity  = 10
  write_capacity = 10
}

# Clients table
resource "aws_dynamodb_table" "rdss_am_clients" {
  name     = "rdss_am_clients"
  hash_key = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

  read_capacity  = 10
  write_capacity = 10
}

# Metadata table
resource "aws_dynamodb_table" "rdss_am_metadata" {
  name     = "rdss_am_metadata"
  hash_key = "Key"

  attribute {
    name = "Key"
    type = "S"
  }

  read_capacity  = 10
  write_capacity = 10
}
