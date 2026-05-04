variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  type        = string
  description = "Project name used in resource naming and tagging"
  default     = "clauderocks"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_name))
    error_message = "Project name must be 3-25 lowercase alphanumeric characters or hyphens, starting with a letter."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "us-east-1"
}

variable "owner" {
  type        = string
  description = "Owner tag value"
  default     = "clauderocks-team"
}

variable "bedrock_model_ids" {
  type        = list(string)
  description = "List of Bedrock inference profile IDs to enable (e.g., us.anthropic.claude-sonnet-4-20250514-v1:0)"
  default     = ["us.anthropic.claude-opus-4-7"]
  validation {
    condition     = length(var.bedrock_model_ids) > 0
    error_message = "At least one Bedrock model ID must be specified."
  }
}

variable "enable_vpc_endpoints" {
  type        = bool
  description = "Whether to create VPC endpoints for private Bedrock access"
  default     = false
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "monthly_budget_limit" {
  type        = number
  description = "Monthly budget limit in USD"
  validation {
    condition     = var.monthly_budget_limit > 0
    error_message = "Monthly budget limit must be a positive number."
  }
}

variable "alert_emails" {
  type        = list(string)
  description = "Email addresses for budget and alarm notifications"
  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "At least one alert email must be specified."
  }
}

variable "max_session_duration" {
  type        = number
  description = "Maximum IAM role session duration in seconds"
  default     = 3600
  validation {
    condition     = var.max_session_duration >= 900 && var.max_session_duration <= 43200
    error_message = "Session duration must be between 900 and 43200 seconds."
  }
}

variable "secret_rotation_days" {
  type        = number
  description = "Secrets Manager rotation interval in days"
  default     = 90
  validation {
    condition     = var.secret_rotation_days >= 1 && var.secret_rotation_days <= 365
    error_message = "Rotation interval must be between 1 and 365 days."
  }
}

variable "cloudtrail_retention_days" {
  type        = number
  description = "CloudTrail log retention period in days"
  default     = 90
  validation {
    condition     = var.cloudtrail_retention_days >= 1
    error_message = "Retention period must be at least 1 day."
  }
}

variable "alarm_error_threshold" {
  type        = number
  description = "Bedrock API error rate threshold for CloudWatch alarm"
  default     = 5
  validation {
    condition     = var.alarm_error_threshold > 0
    error_message = "Error threshold must be a positive number."
  }
}
