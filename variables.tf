variable "chatbot_name" {
  default = "chatbot-agent"
  type = string
}

variable "chatbot_foundation_model" {
  default = "amazon.nova-pro-v1:0"
  type = string
}

variable "chatbot_instruction" {
  default = "You are a friendly assistant who helps answer questions."
  type = string
}