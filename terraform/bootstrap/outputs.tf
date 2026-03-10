output "state_bucket_name" {
  description = "S3 bucket name for Terraform state — set as bucket in environment backends"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN to set as AWS_OIDC_ROLE_ARN in GitHub repository secrets"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = local.oidc_provider_arn
}
