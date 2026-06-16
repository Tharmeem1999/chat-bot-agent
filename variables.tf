variable "chatbot_name" {
  default = "chatbot-agent"
  type = string
}

variable "chatbot_foundation_model" {
  default = "amazon.nova-pro-v1:0"
  type = string
}

variable "knowledge_base_name" {
  default = "shop-inventory-kb"
}

variable "data_source_name" {
  default = "inventory-s3-data-source"
}