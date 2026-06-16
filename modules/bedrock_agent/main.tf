data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}


# --- IAM Role and Policy for Bedrock Agent ---

data "aws_iam_policy_document" "agent_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["bedrock.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "ArnLike"
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:agent/*"]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "agent_permissions" {
  statement {
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}::foundation-model/*",
      "arn:${data.aws_partition.current.partition}:bedrock:*::foundation-model/*",
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/*",
      "arn:${data.aws_partition.current.partition}:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*",
    ]
  }

  statement {
    actions   = ["bedrock:Retrieve", "bedrock:RetrieveAndGenerate"]
    resources = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
  }
}

resource "aws_iam_role" "agent_role" {
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role.json
  name_prefix        = "AmazonBedrockExecutionRoleForAgents_"
}

resource "aws_iam_role_policy" "agent_policy" {
  policy = data.aws_iam_policy_document.agent_permissions.json
  role   = aws_iam_role.agent_role.id
}


# --- Bedrock Agent ---

resource "aws_bedrockagent_agent" "agent" {
  agent_name                  = var.agent_name
  agent_resource_role_arn     = aws_iam_role.agent_role.arn
  idle_session_ttl_in_seconds = var.idle_session_ttl
  instruction                 = var.instruction
  foundation_model            = var.foundation_model

  memory_configuration {
    enabled_memory_types = ["SESSION_SUMMARY"]
    storage_days = var.memory_storage_days
  }
}