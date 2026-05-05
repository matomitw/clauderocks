# =============================================================================
# Root Module — Module Orchestration
# =============================================================================
# This file instantiates all child modules and wires inter-module dependencies.
#
# Dependency graph:
#   state-backend  — no dependencies
#   iam            — no dependencies
#   bedrock        — no dependencies (iam_role_arn wiring is for networking only)
#   networking     — depends on iam (iam_role_arn); conditional on enable_vpc_endpoints
#   budget         — no dependencies
#   monitoring     — depends on budget (sns_topic_arn)
#
# Requirements: 10.1, 10.2, 9.2
# =============================================================================

# -----------------------------------------------------------------------------
# State Backend Module
# -----------------------------------------------------------------------------
# Provisions S3 bucket and DynamoDB table for Terraform remote state.
# Requirements: 1.1, 1.2, 1.3, 1.4, 1.6
# -----------------------------------------------------------------------------
module "state_backend" {
  source = "./modules/state-backend"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.common_tags
}

# -----------------------------------------------------------------------------
# IAM Module
# -----------------------------------------------------------------------------
# Creates IAM user, role, policy, access keys, and Secrets Manager secret
# for Claude Code CLI Bedrock access.
# Requirements: 2.1–2.8, 8.1–8.5
# -----------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  environment          = var.environment
  project_name         = var.project_name
  max_session_duration = var.max_session_duration
  tags                 = local.common_tags
}

# -----------------------------------------------------------------------------
# Bedrock Module
# -----------------------------------------------------------------------------
# Configures Amazon Bedrock model access for specified Claude models.
# Requirements: 3.1–3.6
# -----------------------------------------------------------------------------
module "bedrock" {
  source = "./modules/bedrock"

  environment = var.environment
  model_ids   = var.bedrock_model_ids
  tags        = local.common_tags
}

# -----------------------------------------------------------------------------
# Networking Module (Conditional)
# -----------------------------------------------------------------------------
# Creates VPC and VPC endpoints for private Bedrock access.
# Only instantiated when var.enable_vpc_endpoints is true.
# Depends on: iam (iam_role_arn for VPC endpoint policy)
# Requirements: 5.1–5.7
# -----------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"
  count  = var.enable_vpc_endpoints ? 1 : 0

  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  enable_vpc_endpoints = var.enable_vpc_endpoints
  iam_role_arn         = module.iam.iam_role_arn
  region               = var.aws_region
  tags                 = local.common_tags
}

# -----------------------------------------------------------------------------
# Budget Module
# -----------------------------------------------------------------------------
# Creates AWS Budgets with SNS alert notifications at configurable thresholds.
# Requirements: 6.1–6.6
# -----------------------------------------------------------------------------
module "budget" {
  source = "./modules/budget"

  environment          = var.environment
  project_name         = var.project_name
  monthly_budget_limit = var.monthly_budget_limit
  alert_emails         = var.alert_emails
  cost_allocation_tags = local.common_tags
  tags                 = local.common_tags
}

# -----------------------------------------------------------------------------
# Monitoring Module
# -----------------------------------------------------------------------------
# Sets up CloudWatch dashboards, alarms, and CloudTrail audit logging.
# Depends on: budget (sns_topic_arn for alarm notifications)
# Requirements: 7.1–7.7
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  environment               = var.environment
  project_name              = var.project_name
  alarm_error_threshold     = var.alarm_error_threshold
  cloudtrail_retention_days = var.cloudtrail_retention_days
  alarm_sns_topic_arn       = module.budget.sns_topic_arn
  tags                      = local.common_tags
}
