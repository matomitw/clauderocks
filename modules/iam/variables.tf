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
  default     = "clauderocks"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_name))
    error_message = "Project name must be 3-25 lowercase alphanumeric characters or hyphens, starting with a letter."
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

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}
