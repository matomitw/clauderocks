################################################################################
# Bedrock Module - Model Access Configuration and Invocation Logging
################################################################################

# --- Local Values ---

locals {
  name_prefix = "clauderocks-${var.environment}"
}

# --- Data Sources ---

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# --- CloudWatch Log Group for Bedrock Invocation Logging ---

resource "aws_cloudwatch_log_group" "bedrock_invocation" {
  name              = "/aws/bedrock/${local.name_prefix}/invocation-logs"
  retention_in_days = 90

  tags = var.tags
}

# --- IAM Role for Bedrock Invocation Logging ---

resource "aws_iam_role" "bedrock_logging" {
  name = "${local.name_prefix}-bedrock-logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "bedrock_logging" {
  name = "${local.name_prefix}-bedrock-logging"
  role = aws_iam_role.bedrock_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.bedrock_invocation.arn}:*"
      }
    ]
  })
}

# --- Bedrock Model Invocation Logging Configuration ---

resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  logging_config {
    embedding_data_delivery_enabled = true

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock_invocation.name
      role_arn       = aws_iam_role.bedrock_logging.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.bedrock_logging
  ]
}
