variable "name_kb" {
  description = "The name of the Bedrock Agent Knowledge Base."
  type        = string
}

variable "bucket_name" {
  description = "The S3 bucket name that the Knowledge Base will sync from."
  type        = string
}