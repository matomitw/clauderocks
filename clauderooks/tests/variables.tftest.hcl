# Variable Validation Tests
# Validates: Requirements 17.4, 17.5, 17.6
#
# These tests verify that root-level variable validation blocks correctly
# reject invalid inputs and accept valid inputs. Uses mock_provider to
# avoid needing real AWS credentials.

mock_provider "aws" {}

# --- Test: Invalid environment value is rejected ---
# Validates: Requirement 17.4 — descriptive error for invalid variable values
run "invalid_environment_rejected" {
  command = plan

  variables {
    environment          = "invalid"
    monthly_budget_limit = 50
    alert_emails         = ["test@example.com"]
  }

  expect_failures = [
    var.environment,
  ]
}

# --- Test: Empty bedrock_model_ids list is rejected ---
# Validates: Requirement 17.4 — at least one Bedrock model ID must be specified
run "empty_model_list_rejected" {
  command = plan

  variables {
    environment          = "dev"
    monthly_budget_limit = 50
    alert_emails         = ["test@example.com"]
    bedrock_model_ids    = []
  }

  expect_failures = [
    var.bedrock_model_ids,
  ]
}

# --- Test: Valid dev environment with all required variables is accepted ---
# Validates: Requirements 17.5, 17.6 — valid inputs produce a successful plan
run "valid_dev_environment_accepted" {
  command = plan

  variables {
    environment          = "dev"
    monthly_budget_limit = 50
    alert_emails         = ["test@example.com"]
  }
}

# --- Test: Invalid vpc_cidr is rejected ---
# Validates: Requirement 17.4 — VPC CIDR must be a valid CIDR block
run "invalid_vpc_cidr_rejected" {
  command = plan

  variables {
    environment          = "dev"
    monthly_budget_limit = 50
    alert_emails         = ["test@example.com"]
    vpc_cidr             = "not-a-cidr"
  }

  expect_failures = [
    var.vpc_cidr,
  ]
}

# --- Test: Monthly budget limit of 0 is rejected ---
# Validates: Requirement 17.4 — monthly budget limit must be a positive number
run "zero_budget_limit_rejected" {
  command = plan

  variables {
    environment          = "dev"
    monthly_budget_limit = 0
    alert_emails         = ["test@example.com"]
  }

  expect_failures = [
    var.monthly_budget_limit,
  ]
}

# --- Test: Negative monthly budget limit is rejected ---
# Validates: Requirement 17.4 — monthly budget limit must be a positive number
run "negative_budget_limit_rejected" {
  command = plan

  variables {
    environment          = "dev"
    monthly_budget_limit = -10
    alert_emails         = ["test@example.com"]
  }

  expect_failures = [
    var.monthly_budget_limit,
  ]
}
