variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  type        = string
  description = "AWS region for Bedrock"
  default     = "us-east-1"
}

variable "model_ids" {
  type        = list(string)
  description = "List of Bedrock model identifiers to enable"
  validation {
    condition     = length(var.model_ids) > 0
    error_message = "At least one Bedrock model ID must be specified."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}
