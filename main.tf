terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "ospsd-terraform-state"
    key    = "apprunner/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "apprunner_ecr_role" {
  name = "apprunner-ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role" "apprunner_instance_role" {
  name = "apprunner-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "tasks.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_s3_policy" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_apprunner_service" "app" {
  service_name = "ospsd-cloud-service"

  instance_configuration {
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
    cpu               = "1024"
    memory            = "2048"
  }

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
    image_repository {
      image_identifier      = var.image_url
      image_repository_type = "ECR"
      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          OPENAI_API_KEY        = var.openai_api_key
          OPENAI_MODEL          = var.openai_model
          AGENT_API_KEY         = var.agent_api_key
          SESSION_SECRET_KEY    = var.session_secret_key
          OAUTH_CLIENT_ID       = var.oauth_client_id
          OAUTH_CLIENT_SECRET   = var.oauth_client_secret
          OAUTH_AUTH_URL        = "https://github.com/login/oauth/authorize"
          OAUTH_TOKEN_URL       = "https://github.com/login/oauth/access_token"
          OAUTH_REDIRECT_URI    = var.oauth_redirect_uri
          OAUTH_SCOPE           = "repo"
          AWS_S3_BUCKET         = var.aws_s3_bucket
          AWS_REGION            = "us-east-1"
          BASE_URL              = var.base_url
          CHAT_SERVICE_BASE_URL = var.chat_service_base_url
          ENV                   = "production"
        }
      }
    }
    auto_deployments_enabled = true
  }
}