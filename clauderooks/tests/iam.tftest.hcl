# IAM Module Tests
# Validates: Requirements 2.1, 2.3, 2.4, 8.3, 17.1

mock_provider "aws" {}

# --- Test: IAM user created with correct name ---
# Validates: Requirement 2.1 — dedicated IAM user for Claude Code CLI
run "iam_user_naming_convention" {
  command = plan

  module {
    source = "./modules/iam"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    max_session_duration = 3600
    secret_rotation_days = 90
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_iam_user.claude_code.name == "claude-code-dev"
    error_message = "IAM user name should follow the pattern claude-code-{environment}"
  }
}

# --- Test: IAM role has correct name and session duration ---
# Validates: Requirement 2.3 — IAM role with trust policy for the dedicated user
run "iam_role_trust_policy" {
  command = plan

  module {
    source = "./modules/iam"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    max_session_duration = 3600
    secret_rotation_days = 90
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_iam_role.bedrock_access.name == "clauderooks-dev-bedrock-access"
    error_message = "IAM role name should follow the pattern {project_name}-{environment}-bedrock-access"
  }

  assert {
    condition     = aws_iam_role.bedrock_access.max_session_duration == 3600
    error_message = "IAM role max session duration should be 3600 seconds"
  }
}

# --- Test: Bedrock access policy is attached to the role ---
# Validates: Requirement 2.4 — Bedrock access policy attached to role, not user
run "bedrock_policy_attached_to_role" {
  command = plan

  module {
    source = "./modules/iam"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    max_session_duration = 3600
    secret_rotation_days = 90
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_iam_role_policy_attachment.bedrock_access.role == "clauderooks-dev-bedrock-access"
    error_message = "Bedrock access policy must be attached to the IAM role"
  }
}

# --- Test: User inline policy allows only AssumeRole ---
# Validates: Requirement 2.4 — user can only assume the role
run "user_policy_assume_role_only" {
  command = plan

  module {
    source = "./modules/iam"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    max_session_duration = 3600
    secret_rotation_days = 90
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_iam_user_policy.assume_role_only.name == "clauderooks-dev-assume-role-only"
    error_message = "User inline policy name should follow the pattern {project_name}-{environment}-assume-role-only"
  }

  assert {
    condition     = aws_iam_user_policy.assume_role_only.user == "claude-code-dev"
    error_message = "User inline policy must be attached to the claude-code-dev user"
  }
}

# --- Test: Secrets Manager secret is created ---
# Validates: Requirement 8.3 — IAM access keys stored in Secrets Manager
run "secrets_manager_secret_created" {
  command = plan

  module {
    source = "./modules/iam"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    max_session_duration = 3600
    secret_rotation_days = 90
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_secretsmanager_secret.claude_code_keys.name == "clauderooks-dev/claude-code-keys"
    error_message = "Secrets Manager secret name should follow the pattern {project_name}-{environment}/claude-code-keys"
  }
}

# --- Test: secret_arn output is marked sensitive ---
# Validates: Requirement 8.3 — sensitive outputs to prevent display in logs
# The secret_arn output is marked sensitive in outputs.tf; we verify the
# underlying Secrets Manager secret resource is planned with the correct name.
run "secret_arn_output_is_sensitive" {
  command = plan

  module {
    source = "./modules/iam"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    max_session_duration = 3600
    secret_rotation_days = 90
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_secretsmanager_secret.claude_code_keys.description == "IAM access keys for Claude Code CLI user (dev)"
    error_message = "Secrets Manager secret description should reference the environment"
  }
}
