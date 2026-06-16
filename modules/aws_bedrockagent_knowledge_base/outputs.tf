output "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base, used to attach data sources."
  value       = aws_bedrockagent_knowledge_base.inventory_kb.id
}