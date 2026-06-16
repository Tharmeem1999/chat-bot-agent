data "aws_region" "current" {}

resource "aws_bedrockagent_data_source" "inventory_s3" {
  name              = var.name_ds
  # Links this data source to the Knowledge Base created
  knowledge_base_id = var.knowledge_base_id

  data_source_configuration {
    type = "S3"
    s3_configuration {
      # The S3 bucket where you will upload your inventory.csv or inventory.txt
      bucket_arn = var.bucket_arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        # Breaks your document into chunks of 300 tokens to ensure the AI can retrieve highly specific inventory items accurately
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}

resource "null_resource" "sync_data_source" {
  triggers = {
    data_source_id = aws_bedrockagent_data_source.inventory_s3.data_source_id
  }

  provisioner "local-exec" {
    command = "aws bedrock-agent start-ingestion-job --knowledge-base-id ${var.knowledge_base_id} --data-source-id ${aws_bedrockagent_data_source.inventory_s3.data_source_id} --region ${data.aws_region.current.region}"
  }

  depends_on = [aws_bedrockagent_data_source.inventory_s3]
}