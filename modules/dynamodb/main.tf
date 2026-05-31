resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "conversation_id"

  attribute {
    name = "conversation_id"
    type = "S"
  }
}