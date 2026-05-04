# -----------------------------------------------------------------------------
# Budget Module Outputs
# -----------------------------------------------------------------------------

output "budget_id" {
  description = "ID of the AWS Budget"
  value       = aws_budgets_budget.monthly.id
}

output "sns_topic_arn" {
  description = "ARN of the budget alert SNS topic"
  value       = aws_sns_topic.budget_alerts.arn
}
