# --- Bedrock Agent ---
module "bedrock_agent" {
  source = "./modules/bedrock_agent"

  agent_name = "${var.chatbot_name}"
  foundation_model = "${var.chatbot_foundation_model}"
  instruction = file("${path.module}/instructions.txt")
}

# --- DynamoDB ---
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name = "${var.chatbot_name}-conversations"
}

# --- S3 Bucket ---
module "s3_bucket" {
  source = "./modules/s3_bucket"
  
  bucket_name = "${var.chatbot_name}-files"
}


# --- S3 Bucket Object ---
module "s3_bucket_object" {
  source = "./modules/s3_bucket_object"

  bucket_name = "${var.chatbot_name}-files"
  bucket_key = "product_inventory.csv"
  bucket_source = "${path.module}/product_inventory.csv"
}