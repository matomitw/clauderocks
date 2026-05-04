# Budget Module Tests
# Validates: Requirements 6.2, 17.1

mock_provider "aws" {}

# --- Test: Budget type is COST and time unit is MONTHLY ---
# Validates: Requirement 6.1 — Monthly cost budget
run "budget_type_cost_and_monthly" {
  command = plan

  module {
    source = "./modules/budget"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderocks"
    monthly_budget_limit = 100
    alert_emails         = ["test@example.com"]
    cost_allocation_tags = { Project = "clauderocks" }
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_budgets_budget.monthly.budget_type == "COST"
    error_message = "Budget type should be COST"
  }

  assert {
    condition     = aws_budgets_budget.monthly.time_unit == "MONTHLY"
    error_message = "Budget time unit should be MONTHLY"
  }
}

# --- Test: Budget limit matches the configured monthly_budget_limit ---
# Validates: Requirement 6.1 — Configurable monthly spending limit
run "budget_limit_matches_variable" {
  command = plan

  module {
    source = "./modules/budget"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderocks"
    monthly_budget_limit = 100
    alert_emails         = ["test@example.com"]
    cost_allocation_tags = { Project = "clauderocks" }
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_budgets_budget.monthly.limit_amount == "100"
    error_message = "Budget limit amount should match the configured monthly_budget_limit (100)"
  }

  assert {
    condition     = aws_budgets_budget.monthly.limit_unit == "USD"
    error_message = "Budget limit unit should be USD"
  }
}

# --- Test: Budget has three notification blocks with correct thresholds ---
# Validates: Requirement 6.2 — Alert notifications at 50%, 80%, and 100% of the budget threshold
run "budget_notification_thresholds" {
  command = plan

  module {
    source = "./modules/budget"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderocks"
    monthly_budget_limit = 100
    alert_emails         = ["test@example.com"]
    cost_allocation_tags = { Project = "clauderocks" }
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  # Verify the three notification thresholds exist by checking for each value in the set
  assert {
    condition = anytrue([
      for n in aws_budgets_budget.monthly.notification : n.threshold == 50
    ])
    error_message = "Budget should have a notification with 50% threshold"
  }

  assert {
    condition = anytrue([
      for n in aws_budgets_budget.monthly.notification : n.threshold == 80
    ])
    error_message = "Budget should have a notification with 80% threshold"
  }

  assert {
    condition = anytrue([
      for n in aws_budgets_budget.monthly.notification : n.threshold == 100
    ])
    error_message = "Budget should have a notification with 100% threshold"
  }

  # Verify all thresholds use PERCENTAGE type
  assert {
    condition = alltrue([
      for n in aws_budgets_budget.monthly.notification : n.threshold_type == "PERCENTAGE"
    ])
    error_message = "All notification thresholds should use PERCENTAGE type"
  }

  # Verify we have exactly three notifications
  assert {
    condition = length([
      for n in aws_budgets_budget.monthly.notification : n.threshold
    ]) == 3
    error_message = "Budget should have exactly three notification blocks (50%, 80%, 100%)"
  }
}

# --- Test: SNS topic is created with correct naming ---
# Validates: Requirement 6.3 — Alert notifications via SNS
run "sns_topic_correct_naming" {
  command = plan

  module {
    source = "./modules/budget"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderocks"
    monthly_budget_limit = 100
    alert_emails         = ["test@example.com"]
    cost_allocation_tags = { Project = "clauderocks" }
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_sns_topic.budget_alerts.name == "clauderocks-dev-budget-alerts"
    error_message = "SNS topic name should follow the naming convention: clauderocks-dev-budget-alerts"
  }
}

# --- Test: Budget name follows naming convention ---
# Validates: Requirement 6.5 — Tagging strategy applied to budget resources
run "budget_name_follows_convention" {
  command = plan

  module {
    source = "./modules/budget"
  }

  variables {
    environment          = "dev"
    project_name         = "clauderocks"
    monthly_budget_limit = 100
    alert_emails         = ["test@example.com"]
    cost_allocation_tags = { Project = "clauderocks" }
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_budgets_budget.monthly.name == "clauderocks-dev-monthly-budget"
    error_message = "Budget name should follow the naming convention: clauderocks-dev-monthly-budget"
  }
}
