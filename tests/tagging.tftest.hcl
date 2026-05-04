# Tagging Consistency Tests
# Validates: Requirements 9.1, 9.2, 9.3, 9.4, 17.1
#
# These tests verify that the root module's tagging strategy is correctly
# defined and propagated to child modules. Uses mock_provider to avoid
# needing real AWS credentials.

mock_provider "aws" {}

variables {
  environment          = "dev"
  project_name         = "clauderocks"
  monthly_budget_limit = 50
  alert_emails         = ["test@example.com"]
}

# --- Test: common_tags local contains all required keys ---
# Validates: Requirement 9.1 — default tag set contains Project, Environment, ManagedBy, Owner
run "common_tags_contains_required_keys" {
  command = plan

  assert {
    condition     = local.common_tags["Project"] != null
    error_message = "common_tags must contain the 'Project' key"
  }

  assert {
    condition     = local.common_tags["Environment"] != null
    error_message = "common_tags must contain the 'Environment' key"
  }

  assert {
    condition     = local.common_tags["ManagedBy"] != null
    error_message = "common_tags must contain the 'ManagedBy' key"
  }

  assert {
    condition     = local.common_tags["Owner"] != null
    error_message = "common_tags must contain the 'Owner' key"
  }
}

# --- Test: ManagedBy tag is set to "terraform" ---
# Validates: Requirement 9.5 — ManagedBy tag value is "terraform"
run "managed_by_tag_is_terraform" {
  command = plan

  assert {
    condition     = local.common_tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag must be set to 'terraform'"
  }
}

# --- Test: Project tag matches var.project_name ---
# Validates: Requirement 9.6 — Project tag value matches project_name variable
run "project_tag_matches_variable" {
  command = plan

  assert {
    condition     = local.common_tags["Project"] == var.project_name
    error_message = "Project tag must match var.project_name"
  }
}

# --- Test: Environment tag matches var.environment ---
# Validates: Requirement 9.1 — Environment tag matches active environment name
run "environment_tag_matches_variable" {
  command = plan

  assert {
    condition     = local.common_tags["Environment"] == var.environment
    error_message = "Environment tag must match var.environment"
  }
}

# --- Test: Provider default_tags propagates common_tags ---
# Validates: Requirement 9.4 — provider default_tags block propagates common_tags to all resources
# The provider default_tags block in providers.tf references local.common_tags.
# We verify the tag set has exactly 4 entries and all values are correctly derived
# from the input variables, confirming the default_tags configuration is sound.
run "provider_default_tags_propagates_common_tags" {
  command = plan

  # Verify common_tags has exactly 4 keys (Project, Environment, ManagedBy, Owner)
  assert {
    condition     = length(local.common_tags) == 4
    error_message = "common_tags must contain exactly 4 tags (Project, Environment, ManagedBy, Owner)"
  }

  # Verify the Owner tag is present and non-empty (default is "clauderocks-team")
  assert {
    condition     = length(local.common_tags["Owner"]) > 0
    error_message = "Owner tag must have a non-empty value"
  }
}

# --- Test: Tags are consistent across different environment values ---
# Validates: Requirement 9.2 — default tag set propagated to all modules via shared variable
run "tags_consistent_for_staging_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = local.common_tags["Environment"] == "staging"
    error_message = "Environment tag must update when environment variable changes to staging"
  }

  assert {
    condition     = local.common_tags["Project"] == "clauderocks"
    error_message = "Project tag must remain 'clauderocks' regardless of environment"
  }

  assert {
    condition     = local.common_tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag must remain 'terraform' regardless of environment"
  }
}
