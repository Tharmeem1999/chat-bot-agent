############################################
# Trust policy: let Bedrock assume the role
############################################
data "aws_iam_policy_document" "bedrock_kb_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
  }
}

############################################
# IAM role for the Bedrock Knowledge Base
############################################
resource "aws_iam_role" "bedrock_kb_role" {
  name               = "${var.name_kb}-role"
  assume_role_policy = data.aws_iam_policy_document.bedrock_kb_assume_role.json
}

############################################
# Inline policy: Bedrock model + OpenSearch
############################################
data "aws_iam_policy_document" "bedrock_kb_policy" {
  statement {
    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"]
  }

  statement {
    actions   = ["aoss:APIAccessAll"]
    resources = ["*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
  }
}

resource "aws_iam_role_policy" "bedrock_kb_policy" {
  role   = aws_iam_role.bedrock_kb_role.id
  policy = data.aws_iam_policy_document.bedrock_kb_policy.json
}

############################################
# Caller identity (for the access policy)
############################################
data "aws_caller_identity" "current" {}

############################################
# OpenSearch Serverless security policies
############################################
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.name_kb}-enc"
  type = "encryption"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.name_kb}"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.name_kb}-net"
  type = "network"
  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.name_kb}"]
    }]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_access_policy" "data" {
  name = "${var.name_kb}-access"
  type = "data"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.name_kb}"]
        Permission   = ["aoss:*"]
      },
      {
        ResourceType = "index"
        # Must be index/<collection>/<index-or-*>.
        # The collection name is var.name_kb; Bedrock creates a default
        # index named "bedrock-knowledge-base-default-index" inside it,
        # and the wildcard covers it (and any future indexes in this collection).
        Resource = [
          "index/${var.name_kb}/*",
        ]
        Permission = ["aoss:*"]
      }
    ]
    Principal = [
      aws_iam_role.bedrock_kb_role.arn,
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    ]
  }])
}

############################################
# OpenSearch Serverless vector collection
############################################
resource "aws_opensearchserverless_collection" "vector_store" {
  name = var.name_kb
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.data,
  ]
}

############################################
# Wait for the OpenSearch collection to be ACTIVE
############################################
resource "time_sleep" "wait_for_collection" {
  depends_on      = [aws_opensearchserverless_collection.vector_store]
  create_duration = "60s"
}

############################################
# Pre-create the vector index Bedrock expects
############################################
resource "null_resource" "bedrock_index" {
  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.vector_store.collection_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      awscurl --service aoss --region us-east-1 \
        -X PUT "${aws_opensearchserverless_collection.vector_store.collection_endpoint}/bedrock-knowledge-base-default-index" \
        -H 'Content-Type: application/json' \
        -d '{
          "settings": { "index.knn": true },
          "mappings": {
            "properties": {
              "bedrock-knowledge-base-default-vector": {
                "type": "knn_vector",
                "dimension": 1024,
                "method": { "engine": "faiss", "name": "hnsw", "space_type": "l2" }
              },
              "AMAZON_BEDROCK_TEXT_CHUNK": { "type": "text" },
              "AMAZON_BEDROCK_METADATA":  { "type": "text", "index": false }
            }
          }
        }'
    EOT
  }

  depends_on = [time_sleep.wait_for_collection]
}

############################################
# Bedrock Knowledge Base
############################################
resource "aws_bedrockagent_knowledge_base" "inventory_kb" {
  name     = var.name_kb
  role_arn = aws_iam_role.bedrock_kb_role.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }

  # This maps Bedrock to your specific Vector Database
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.vector_store.arn
      vector_index_name = "bedrock-knowledge-base-default-index"

      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.bedrock_kb_policy,
    null_resource.bedrock_index,
  ]
}
