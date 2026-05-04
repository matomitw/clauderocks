# =============================================================================
# Root Outputs
# =============================================================================
# Exposes key outputs from all child modules for downstream consumption.
#
# Requirements: 10.4 — Root SHALL expose module outputs through outputs.tf files.
#               8.3  — IAM access key outputs marked sensitive.
# =============================================================================

# -----------------------------------------------------------------------------
# State Backend Module Outputs
# -----------------------------------------------------------------------------

output "state_bucket_name" {
  description = "Name of the S3 state bucket"
  value       = module.state_backend.state_bucket_name
}

output "state_bucket_arn" {
  description = "ARN of the S3 state bucket"
  value       = module.state_backend.state_bucket_arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB lock table"
  value       = module.state_backend.lock_table_name
}

# -----------------------------------------------------------------------------
# IAM Module Outputs
# -----------------------------------------------------------------------------

output "iam_user_name" {
  description = "Name of the IAM user"
  value       = module.iam.iam_user_name
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = module.iam.iam_user_arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.iam.iam_role_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.iam.iam_role_arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing IAM access keys"
  value       = module.iam.secret_arn
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Bedrock Module Outputs
# -----------------------------------------------------------------------------

output "enabled_model_arns" {
  description = "ARNs of enabled Bedrock models"
  value       = module.bedrock.enabled_model_arns
}

# -----------------------------------------------------------------------------
# Networking Module Outputs (conditional — module uses count)
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC (empty string if VPC endpoints are disabled)"
  value       = try(module.networking[0].vpc_id, "")
}

output "private_subnet_ids" {
  description = "IDs of private subnets (empty list if VPC endpoints are disabled)"
  value       = try(module.networking[0].private_subnet_ids, [])
}

# -----------------------------------------------------------------------------
# Monitoring Module Outputs
# -----------------------------------------------------------------------------

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.monitoring.cloudtrail_arn
}

# -----------------------------------------------------------------------------
# Budget Module Outputs
# -----------------------------------------------------------------------------

output "budget_sns_topic_arn" {
  description = "ARN of the budget alert SNS topic"
  value       = module.budget.sns_topic_arn
}
