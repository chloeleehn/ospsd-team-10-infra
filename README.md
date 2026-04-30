# ospsd-team-10-infra

**Related Repositories:** [ospsd-team-10](https://github.com/thisisadi/ospsd-team-10) — FastAPI application source code and app CI/CD pipeline

## Overview

This repository manages the AWS infrastructure for the OSPSD Team 10 cloud service, managed with Terraform and deployed via CircleCI.

- **AWS App Runner** — runs the containerized FastAPI application
- **Amazon ECR** — stores Docker images built by the app pipeline
- **IAM Roles** — controls permissions for ECR access and S3 access
- **S3 Remote State** — stores Terraform state across CI runs

## Architecture

```
App Repo (ospsd-team-10)
        │
        ▼
  CircleCI App Pipeline
        │
        ▼
  Docker Image → ECR
        │
        ▼ (auto_deployments_enabled = true)
  AWS App Runner ←── Terraform (this repo)
        │
        ▼
  Live Service: https://edbym5kujh.us-east-1.awsapprunner.com
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0.0
- AWS CLI configured with appropriate credentials
- Access to the AWS account

## Repository Structure

```
ospsd-team-10-infra/
├── main.tf          # Main Terraform configuration
├── variables.tf     # Input variable definitions
├── outputs.tf       # Output values (e.g. service URL)
├── terraform.tfvars # Local variable values (never committed)
├── .gitignore       # Excludes secrets and state files
└── .circleci/
    └── config.yml   # CI/CD pipeline for infra
```

## Infrastructure Resources

| Resource                         | Name                      | Purpose                            |
| -------------------------------- | ------------------------- | ---------------------------------- |
| `aws_apprunner_service`          | `ospsd-cloud-service`     | Runs the FastAPI app               |
| `aws_iam_role`                   | `apprunner-ecr-role`      | Allows App Runner to pull from ECR |
| `aws_iam_role`                   | `apprunner-instance-role` | Allows app to access S3            |
| `aws_iam_role_policy_attachment` | `apprunner_ecr_policy`    | Attaches ECR access policy         |
| `aws_iam_role_policy_attachment` | `apprunner_s3_policy`     | Attaches S3 full access policy     |

## Local Development

### 1. Install Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### 2. Create `terraform.tfvars`

```hcl
image_url             = "XXX.dkr.ecr.us-east-1.amazonaws.com/ospsd-cloud-service:latest"
openai_api_key        = "your_openai_key"
openai_model          = "gpt-4o-mini"
agent_api_key         = "your_agent_key"
session_secret_key    = "your_session_secret"
oauth_client_id       = "your_oauth_client_id"
oauth_client_secret   = "your_oauth_client_secret"
oauth_redirect_uri    = "https://edbym5kujh.us-east-1.awsapprunner.com/auth/callback"
aws_s3_bucket         = "test-bucket"
base_url              = "https://edbym5kujh.us-east-1.awsapprunner.com"
chat_service_base_url = "https://os-bmaq.onrender.com"
```

> Don't commit `terraform.tfvars` — it contains secrets.

### 3. Initialize and plan

```bash
terraform init
terraform plan
```

### 4. Apply changes

```bash
terraform apply -auto-approve
```

## CI/CD Pipeline

The infra pipeline runs automatically on every push to this repo.

```
Push to GitHub
      ↓
terraform_plan (automatic)
      ↓
hold (manual approval required)
      ↓
terraform_apply
```

### CircleCI Environment Variables

The following variables must be set in **CircleCI → Project Settings → Environment Variables**:

| Variable                       | Description                                    |
| ------------------------------ | ---------------------------------------------- |
| `AWS_ACCESS_KEY_ID`            | AWS credentials for `circleci-deploy` IAM user |
| `AWS_SECRET_ACCESS_KEY`        | AWS credentials for `circleci-deploy` IAM user |
| `AWS_REGION`                   | AWS region (`us-east-1`)                       |
| `TF_VAR_image_url`             | ECR image URL                                  |
| `TF_VAR_openai_api_key`        | OpenAI API key                                 |
| `TF_VAR_openai_model`          | OpenAI model name                              |
| `TF_VAR_agent_api_key`         | Agent service key                              |
| `TF_VAR_session_secret_key`    | Session secret for OAuth                       |
| `TF_VAR_oauth_client_id`       | GitHub OAuth client ID                         |
| `TF_VAR_oauth_client_secret`   | GitHub OAuth client secret                     |
| `TF_VAR_oauth_redirect_uri`    | OAuth redirect URI                             |
| `TF_VAR_aws_s3_bucket`         | S3 bucket name                                 |
| `TF_VAR_base_url`              | App Runner base URL                            |
| `TF_VAR_chat_service_base_url` | Chat service base URL                          |

## Terraform State

State is stored remotely in S3:

- **Bucket**: `ospsd-terraform-state`
- **Key**: `apprunner/terraform.tfstate`
- **Region**: `us-east-1`

This ensures CircleCI and local runs share the same state.

## Useful Commands

```bash
# See current state
terraform show

# Refresh state from AWS
terraform refresh

# Destroy all resources
terraform destroy

# Force replace a resource
terraform apply -replace="aws_apprunner_service.app"

# Import existing resource into state
terraform import aws_apprunner_service.app <service-arn>
```

## Live Service

| Environment             | URL                                                   |
| ----------------------- | ----------------------------------------------------- |
| Production (App Runner) | https://edbym5kujh.us-east-1.awsapprunner.com         |
| API Docs                | https://edbym5kujh.us-east-1.awsapprunner.com/docs    |
| Metrics                 | https://edbym5kujh.us-east-1.awsapprunner.com/metrics |
