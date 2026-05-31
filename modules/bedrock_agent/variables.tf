variable "agent_name" {
  description = "Name of the Bedrock Agent"
  type = string
}

variable "foundation_model" {
  description = "Bedrock foundation model ID"
  type = string
}

variable "instruction" {
  description = "Instruction prompt for the agent describing its role and behavior"
  type = string
}

variable "idle_session_ttl" {
  description = "Idle session TTL in seconds"
  type = number
  default = 900
}

variable "memory_storage_days" {
  description = "Number of days to retain session memory"
  type = number
  default = 30
}