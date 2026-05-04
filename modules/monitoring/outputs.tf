################################################################################
# Monitoring Module — Outputs
################################################################################

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.bedrock.dashboard_arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.bedrock.arn
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail log bucket"
  value       = aws_s3_bucket.cloudtrail.id
}

output "alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value       = [aws_cloudwatch_metric_alarm.bedrock_errors.arn]
}
