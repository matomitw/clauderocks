variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "clauderooks"
}

variable "alarm_error_threshold" {
  type        = number
  description = "Error rate threshold for CloudWatch alarm"
  default     = 5
  validation {
    condition     = var.alarm_error_threshold > 0
    error_message = "Error threshold must be a positive number."
  }
}

variable "cloudtrail_retention_days" {
  type        = number
  description = "CloudTrail log retention in days"
  default     = 90
  validation {
    condition     = var.cloudtrail_retention_days >= 1
    error_message = "Retention period must be at least 1 day."
  }
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}
