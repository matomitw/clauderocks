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

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "enable_vpc_endpoints" {
  type        = bool
  description = "Whether to create VPC endpoints for private Bedrock access"
  default     = true
}

variable "iam_role_arn" {
  type        = string
  description = "IAM role ARN for VPC endpoint policy"
}

variable "region" {
  type        = string
  description = "AWS region for VPC endpoint service names"
  default     = "us-east-1"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}
