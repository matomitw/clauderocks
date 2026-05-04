################################################################################
# Monitoring Module — CloudWatch Dashboard, Alarms, CloudTrail, and S3 Logs
################################################################################
# Sets up CloudWatch dashboards and alarms for Bedrock API metrics, CloudTrail
# audit logging for Bedrock API events, and encrypted S3 storage for trail logs.
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard — Bedrock Metrics
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "bedrock" {
  dashboard_name = "${local.name_prefix}-bedrock-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Bedrock Invocation Count"
          metrics = [["AWS/Bedrock", "Invocations", { stat = "Sum", period = 300 }]]
          view    = "timeSeries"
          region  = data.aws_region.current.id
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Bedrock Invocation Latency"
          metrics = [["AWS/Bedrock", "InvocationLatency", { stat = "Average", period = 300 }]]
          view    = "timeSeries"
          region  = data.aws_region.current.id
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "Bedrock Invocation Errors"
          metrics = [
            ["AWS/Bedrock", "InvocationClientErrors", { stat = "Sum", period = 300 }],
            ["AWS/Bedrock", "InvocationServerErrors", { stat = "Sum", period = 300 }]
          ]
          view   = "timeSeries"
          region = data.aws_region.current.id
          period = 300
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Metric Alarm — Bedrock Error Rate
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "bedrock_errors" {
  alarm_name          = "${local.name_prefix}-bedrock-error-rate"
  alarm_description   = "Alarm when Bedrock API error rate exceeds ${var.alarm_error_threshold} errors in 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "InvocationClientErrors"
  namespace           = "AWS/Bedrock"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alarm_error_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.alarm_sns_topic_arn]
  ok_actions    = [var.alarm_sns_topic_arn]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# S3 Bucket for CloudTrail Logs
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${local.name_prefix}-cloudtrail-logs"

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "cloudtrail-log-retention"
    status = "Enabled"

    expiration {
      days = var.cloudtrail_retention_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy — Allow CloudTrail to Write Logs
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

# -----------------------------------------------------------------------------
# CloudTrail — Bedrock API Events
# -----------------------------------------------------------------------------

resource "aws_cloudtrail" "bedrock" {
  name                          = "${local.name_prefix}-bedrock-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = var.tags

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}
