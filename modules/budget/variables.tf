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
  description = "Email addresses for budget alerts"
  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "At least one alert email must be specified."
  }
}

variable "cost_allocation_tags" {
  type        = map(string)
  description = "Tags for budget filtering"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}
