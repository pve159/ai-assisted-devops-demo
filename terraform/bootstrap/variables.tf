variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-3"
}

variable "github_repository" {
  description = "GitHub repository in the format owner/repo (used to scope the OIDC trust policy)"
  type        = string
  default     = "pve159/ai-assisted-devops-demo"
}

variable "create_oidc_provider" {
  description = "Set to false if the GitHub OIDC provider already exists in this AWS account"
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider. Required when create_oidc_provider = false."
  type        = string
  default     = null
}
