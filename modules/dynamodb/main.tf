resource "aws_dynamodb_table" "chat_history_v2" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = merge(
    {
      Name        = var.table_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

