# --- Bedrock Agent ---
module "bedrock_agent" {
  source = "./modules/bedrock_agent"

  agent_name = "${var.chatbot_name}"
  foundation_model = "${var.chatbot_foundation_model}"
  instruction = "${var.chatbot_instruction}"
}