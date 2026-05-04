locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# SNS Topic for Budget Alerts
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "budget_alerts" {
  name = "${local.name_prefix}-budget-alerts"
  tags = var.tags
}

# -----------------------------------------------------------------------------
# SNS Topic Subscriptions — one per alert email
# -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "budget_email" {
  for_each = toset(var.alert_emails)

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# -----------------------------------------------------------------------------
# AWS Budget — monthly cost budget with 50%, 80%, 100% alert thresholds
# -----------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly" {
  name         = "${local.name_prefix}-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Filter budget tracking to resources matching cost allocation tags
  dynamic "cost_filter" {
    for_each = var.cost_allocation_tags
    content {
      name   = "TagKeyValue"
      values = ["${cost_filter.key}$${cost_filter.value}"]
    }
  }

  # 50% threshold — forecasted spend
  notification {
    notification_type         = "FORECASTED"
    comparison_operator       = "GREATER_THAN"
    threshold                 = 50
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  # 80% threshold — forecasted spend
  notification {
    notification_type         = "FORECASTED"
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  # 100% threshold — actual spend
  notification {
    notification_type         = "ACTUAL"
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  tags = var.tags
}
