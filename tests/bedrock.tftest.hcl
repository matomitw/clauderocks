# Bedrock Module Tests
# Validates: Requirements 3.2, 3.5, 17.1

mock_provider "aws" {}

mock_provider "null" {}

# --- Test: Module accepts model_ids list and constructs correct ARNs ---
# Validates: Requirement 3.2 — accept a list of model identifiers
run "model_ids_list_acceptance" {
  command = plan

  module {
    source = "./modules/bedrock"
  }

  variables {
    environment = "dev"
    region      = "us-east-1"
    model_ids   = ["anthropic.claude-sonnet-4-20250514"]
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = output.enabled_model_arns == ["arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-20250514"]
    error_message = "Module should construct correct Bedrock model ARNs from model_ids"
  }
}

# --- Test: Region defaults to us-east-1 ---
# Validates: Requirement 3.5 — target us-east-1 by default
run "region_defaults_to_us_east_1" {
  command = plan

  module {
    source = "./modules/bedrock"
  }

  variables {
    environment = "dev"
    model_ids   = ["anthropic.claude-sonnet-4-20250514"]
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = output.enabled_model_arns == ["arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-20250514"]
    error_message = "Region should default to us-east-1 when not explicitly set"
  }
}

# --- Test: CloudWatch log group naming convention ---
# Validates: Requirement 17.1 — resources follow naming conventions
run "cloudwatch_log_group_naming" {
  command = plan

  module {
    source = "./modules/bedrock"
  }

  variables {
    environment = "dev"
    region      = "us-east-1"
    model_ids   = ["anthropic.claude-sonnet-4-20250514"]
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_cloudwatch_log_group.bedrock_invocation.name == "/aws/bedrock/clauderocks-dev/invocation-logs"
    error_message = "CloudWatch log group name should follow /aws/bedrock/{name_prefix}/invocation-logs pattern"
  }

  assert {
    condition     = aws_cloudwatch_log_group.bedrock_invocation.retention_in_days == 90
    error_message = "CloudWatch log group retention should be 90 days"
  }
}

# --- Test: Invocation logging configuration is created ---
# Validates: Requirement 3.2, 17.1 — invocation logging configured
run "invocation_logging_configuration" {
  command = plan

  module {
    source = "./modules/bedrock"
  }

  variables {
    environment = "dev"
    region      = "us-east-1"
    model_ids   = ["anthropic.claude-sonnet-4-20250514"]
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].embedding_data_delivery_enabled == true
    error_message = "Bedrock invocation logging should have embedding data delivery enabled"
  }

  assert {
    condition     = aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].cloudwatch_config[0].log_group_name == "/aws/bedrock/clauderocks-dev/invocation-logs"
    error_message = "Invocation logging should reference the correct CloudWatch log group"
  }
}
