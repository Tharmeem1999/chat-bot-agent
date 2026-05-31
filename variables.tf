variable "chatbot_name" {
  default = "chatbot-agent"
  type = string
}

variable "chatbot_foundation_model" {
  default = "us.anthropic.claude-opus-4-5-20251101-v1:0"
  type = string
}

variable "chatbot_instruction" {
  default = "You are a friendly assistant who helps answer questions."
  type = string
}