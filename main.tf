# --- Bedrock Agent ---
module "bedrock_agent" {
  source = "./modules/bedrock_agent"

  agent_name = "${var.chatbot_name}"
  foundation_model = "${var.chatbot_foundation_model}"
  instruction = file("${path.module}/instructions.txt")
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


# --- Bedrock Agent Knowledge Base ---
module "bedrockagent_knowledge_base" {
  source      = "./modules/aws_bedrockagent_knowledge_base"
  name_kb     = var.knowledge_base_name
  bucket_name = "${var.chatbot_name}-files"
}


# --- Bedrock Agent Data Source ---
module "bedrockagent_data_source" {
  source = "./modules/aws_bedrockagent_data_source"
  name_ds           = var.data_source_name
  knowledge_base_id = module.bedrockagent_knowledge_base.knowledge_base_id
  bucket_arn        = module.s3_bucket.bucket_arn
}


# --- Associate Agent with Knowledge Base ---
resource "aws_bedrockagent_agent_knowledge_base_association" "inventory" {
  agent_id             = module.bedrock_agent.agent_id
  knowledge_base_id    = module.bedrockagent_knowledge_base.knowledge_base_id
  description          = "Product inventory knowledge base"
  knowledge_base_state = "ENABLED"
}