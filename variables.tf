variable "chatbot_name" {
  default = "chatbot-agent"
  type = string
}

variable "chatbot_foundation_model" {
  default = "anthropic.claude-opus-4-1-20250805-v1:0"
  type = string
}

variable "chatbot_instruction" {
  default = "You are a friendly assistant who helps answer questions."
  type = string
}