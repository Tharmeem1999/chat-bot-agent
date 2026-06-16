variable "name_ds" {
  description = "Name of the Bedrock Agent Data Source"
  type        = string
}

variable "knowledge_base_id" {
  description = "ID of the parent Bedrock Knowledge Base"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket holding the source documents"
  type        = string
}