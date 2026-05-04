################################################################################
# IAM Module - Outputs
################################################################################

output "iam_user_name" {
  description = "Name of the IAM user"
  value       = aws_iam_user.claude_code.name
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.claude_code.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.bedrock_access.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.bedrock_access.arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing IAM access keys"
  value       = aws_secretsmanager_secret.claude_code_keys.arn
  sensitive   = true
}
