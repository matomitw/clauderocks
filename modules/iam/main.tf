################################################################################
# IAM Module - User, Role, Policy, Access Keys, Secrets Manager
################################################################################

# --- Local Values ---

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- IAM User ---

resource "aws_iam_user" "claude_code" {
  name = "claude-code-${var.environment}"
  path = "/"

  tags = var.tags
}

# --- IAM Role with Trust Policy for the User ---

resource "aws_iam_role" "bedrock_access" {
  name                 = "${local.name_prefix}-bedrock-access"
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.claude_code.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# --- Bedrock Access Policy ---

resource "aws_iam_policy" "bedrock_access" {
  name        = "${local.name_prefix}-bedrock-access"
  description = "Provides full access to Amazon Bedrock for Claude Code CLI"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockFullAccess"
        Effect = "Allow"
        Action = [
          "bedrock:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "MarketplaceModelAccess"
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# --- Attach Bedrock Policy to Role (not user) ---

resource "aws_iam_role_policy_attachment" "bedrock_access" {
  role       = aws_iam_role.bedrock_access.name
  policy_arn = aws_iam_policy.bedrock_access.arn
}

# --- User Inline Policy: Allow Only AssumeRole ---

resource "aws_iam_user_policy" "assume_role_only" {
  name = "${local.name_prefix}-assume-role-only"
  user = aws_iam_user.claude_code.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAssumeRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.bedrock_access.arn
      }
    ]
  })
}

# --- IAM Access Keys ---

resource "aws_iam_access_key" "claude_code" {
  user = aws_iam_user.claude_code.name
}

# --- Secrets Manager Secret ---

resource "aws_secretsmanager_secret" "claude_code_keys" {
  name        = "${local.name_prefix}/claude-code-keys"
  description = "IAM access keys for Claude Code CLI user (${var.environment})"

  tags = var.tags
}

# --- Secrets Manager Secret Version (stores access key ID and secret key) ---

resource "aws_secretsmanager_secret_version" "claude_code_keys" {
  secret_id = aws_secretsmanager_secret.claude_code_keys.id

  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.claude_code.id
    secret_access_key = aws_iam_access_key.claude_code.secret
  })
}

# --- Secrets Manager Secret Rotation ---
# NOTE: Rotation requires a Lambda function. To enable rotation later:
# 1. Create a Lambda rotation function
# 2. Uncomment and add: rotation_lambda_arn = aws_lambda_function.rotation.arn
#
# resource "aws_secretsmanager_secret_rotation" "claude_code_keys" {
#   secret_id           = aws_secretsmanager_secret.claude_code_keys.id
#   rotation_lambda_arn = "<LAMBDA_ARN>"
#
#   rotation_rules {
#     automatically_after_days = var.secret_rotation_days
#   }
# }
