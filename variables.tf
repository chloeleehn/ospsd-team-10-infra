variable "image_url" {
  type        = string
  description = "ECR image URL including tag"
}

variable "openai_api_key" {
  type      = string
  sensitive = true
}

variable "agent_api_key" {
  type      = string
  sensitive = true
}

variable "session_secret_key" {
  type      = string
  sensitive = true
}

variable "oauth_client_id" {
  type      = string
  sensitive = true
}

variable "oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "oauth_redirect_uri" {
  type = string
}

variable "aws_s3_bucket" {
  type = string
}

variable "chat_service_base_url" {
  type = string
}

variable "openai_model" {
  type    = string
  default = "gpt-4o-mini"
}

variable "base_url" {
  type = string
}