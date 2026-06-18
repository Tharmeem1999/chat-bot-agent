# Serverless Retail AI Assistant on AWS Bedrock

A fully serverless, Infrastructure-as-Code chatbot that answers product-availability and catalog questions using an **Amazon Bedrock Agent** powered by **Amazon Nova Pro**, with an **OpenSearch Serverless** vector store as a Retrieval-Augmented Generation (RAG) knowledge base. The product catalog is uploaded to **S3** and synced into the knowledge base automatically.

---

## Overview

This project deploys an AI shop-assistant chatbot from scratch using Terraform. The agent is grounded in a real CSV inventory (`product_inventory.csv`) so it can answer questions like *"Do you have wireless headphones?"*, *"What features does the smart watch have?"*, or *"Show me everything in stock."* — without hallucinating prices, features, or stock counts.

**How it works (end-to-end):**

1. The CSV catalog is uploaded into an S3 bucket.
2. A Bedrock **Knowledge Base** (vector store in OpenSearch Serverless) ingests and indexes the catalog using the `amazon.titan-embed-text-v2` embedding model.
3. A Bedrock **Agent** is created with a strict system prompt (`instructions.txt`) that forbids guessing and requires referencing the inventory file.
4. The Agent is associated with the Knowledge Base, enabling it to perform RAG lookups on every user turn.
5. End-users converse with the agent through the Bedrock runtime API; the agent retrieves relevant chunks from the vector store and answers using the foundation model.

---

## Tech Stack

| Layer | Technology |
| --- | --- |
| **IaC** | Terraform ≥ 1.5 |
| **Cloud** | AWS (`us-east-1`) |
| **AI Orchestration** | Amazon Bedrock Agent |
| **Foundation Model** | Amazon Nova Pro (`amazon.nova-pro-v1:0`) |
| **Embedding Model** | Amazon Titan Text Embeddings v2 (`amazon.titan-embed-text-v2:0`) |
| **Vector Store** | Amazon OpenSearch Serverless (Vector Search collection) |
| **Storage** | Amazon S3 (catalog source documents) |
| **AuthN/AuthZ** | IAM roles with least-privilege inline policies |
| **Memory** | Bedrock Agent session-summary memory (30 days) |
| **Providers** | `hashicorp/aws` 6.47.0, `hashicorp/time` ~0.11, `hashicorp/null` ~3.0 |

---

## Project Structure

```text
chat-bot-agent/
├── main.tf                          # Root module: wires every submodule together
├── provider.tf                      # AWS provider + required providers declaration
├── variables.tf                     # Root input variables (names, model IDs)
├── instructions.txt                 # System prompt that governs agent behavior
├── product_inventory.csv            # Source catalog ingested into the knowledge base
├── terraform.tfstate                # Terraform state (local backend)
├── terraform.tfstate.backup
└── modules/
    ├── bedrock_agent/               # Bedrock Agent + IAM role + permissions
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf               # → agent_id
    ├── aws_bedrockagent_knowledge_base/   # KB + OpenSearch Serverless + index bootstrap
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf               # → knowledge_base_id
    │   └── versions.tf
    ├── aws_bedrockagent_data_source/      # S3-backed data source + ingestion job trigger
    │   ├── main.tf
    │   ├── variables.tf
    │   └── versions.tf
    ├── s3_bucket/                   # Bucket that hosts the catalog
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf               # → bucket_arn
    └── s3_bucket_object/            # Uploads product_inventory.csv into the bucket
        ├── main.tf
        └── variables.tf
```

---

## Prerequisites

Before deploying, make sure you have:

- **AWS Account** with permissions to create Bedrock Agents, Bedrock Knowledge Bases, OpenSearch Serverless collections, S3 buckets, and IAM roles.
- **Model access enabled** in Amazon Bedrock for the following models in `us-east-1`:
  - `amazon.nova-pro-v1:0` (foundation model)
  - `amazon.titan-embed-text-v2:0` (embedding model)
  > Enable them from the AWS Console → *Amazon Bedrock → Model access*.
- **AWS CLI** configured locally (`aws configure`) with credentials that can call `bedrock-agent`, `s3`, `iam`, and `aoss`.
- **awscurl** installed and available on `PATH` (used to pre-create the OpenSearch vector index).
  ```bash
  pip install awscurl
  ```
- **Terraform** ≥ 1.5
  ```bash
  terraform -version
  ```
- **Git** (optional, for cloning the repo).

---

## Configuration

Default variables (defined in [`variables.tf`](variables.tf)):

| Variable | Default | Description |
| --- | --- | --- |
| `chatbot_name` | `chatbot-agent` | Base name used for the Bedrock agent and the S3 bucket |
| `chatbot_foundation_model` | `amazon.nova-pro-v1:0` | Bedrock foundation model ID |
| `knowledge_base_name` | `shop-inventory-kb` | Name of the Bedrock Knowledge Base and OpenSearch collection |
| `data_source_name` | `inventory-s3-data-source` | Name of the S3-backed data source |

Override any of them by creating a `terraform.tfvars` file:

```hcl
chatbot_name            = "my-shop-bot"
chatbot_foundation_model = "amazon.nova-pro-v1:0"
knowledge_base_name     = "shop-inventory-kb"
data_source_name        = "inventory-s3-data-source"
```

The region is hard-coded to **`us-east-1`** in [`provider.tf`](provider.tf) — change it there if you need a different region (and ensure Bedrock model access is enabled there).

---

## How to Deploy

1. **Clone the repository**
   ```bash
   git clone https://github.com/Tharmeem1999/chat-bot-agent.git
   cd chat-bot-agent
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review the execution plan**
   ```bash
   terraform plan
   ```

4. **Apply the configuration**
   ```bash
   terraform apply
   ```

   The apply creates resources in this order:
   1. S3 bucket (`<chatbot_name>-files`) and uploads `product_inventory.csv`.
   2. OpenSearch Serverless encryption, network, and data-access policies.
   3. OpenSearch Serverless vector collection + `bedrock-knowledge-base-default-index` (via `awscurl`).
   4. Bedrock Knowledge Base (`<knowledge_base_name>`).
   5. S3 data source + automatic ingestion job (sync).
   6. Bedrock Agent (`<chatbot_name>`) with its IAM role.
   7. Knowledge-base ↔ agent association.

5. **Inspect outputs**
   ```bash
   terraform output
   ```
   You should see `agent_id`, `knowledge_base_id`, and `bucket_arn`.

6. **Test the agent** using the AWS CLI or the Bedrock console:
   ```bash
   aws bedrock-agent-runtime invoke-agent \
     --agent-id $(terraform output -raw agent_id) \
     --agent-alias-id TSTALIASID \
     --session-id "demo-$(date +%s)" \
     --input-text "Do you have wireless headphones?" \
     --region us-east-1
   ```
   > Replace `TSTALIASID` with a real agent alias once you create one (e.g., a `DRAFT` or versioned alias).

---

## Updating the Catalog

When the inventory changes:

1. Edit `product_inventory.csv`.
2. Re-upload it to S3:
   ```bash
   aws s3 cp product_inventory.csv s3://<chatbot_name>-files/product_inventory.csv
   ```
3. Trigger a fresh ingestion job:
   ```bash
   aws bedrock-agent start-ingestion-job \
     --knowledge-base-id $(terraform output -raw knowledge_base_id) \
     --data-source-id <DATA_SOURCE_ID> \
     --region us-east-1
   ```

---

## Customizing the Agent

- **Behavior / persona:** edit [`instructions.txt`](instructions.txt). The current prompt enforces:
  - Greeting-only responses for plain "hi / hello".
  - Mandatory lookup against the inventory file.
  - No hallucinated prices, features, or stock counts.
- **Memory:** session-summary memory is enabled with a 30-day retention (see `memory_configuration` in the Bedrock Agent module).
- **Foundation model:** swap `chatbot_foundation_model` in `terraform.tfvars`.

---

## Cleanup

To tear down all resources created by this project:

```bash
terraform destroy -auto-approve
```

> OpenSearch Serverless collections take a few minutes to delete. The destroy step will wait for them.

---

