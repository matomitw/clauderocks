# Monitoring Module Tests
# Validates: Requirements 7.2, 7.5, 17.1

mock_provider "aws" {}

# --- Test: CloudWatch alarm uses configurable error threshold ---
# Validates: Requirement 7.2 — CloudWatch alarms for Bedrock API error rates exceeding a configurable threshold
run "alarm_uses_configurable_threshold" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      id   = "us-east-1"
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.cloudtrail_bucket
    values = {
      json = "{}"
    }
  }

  variables {
    environment               = "dev"
    project_name              = "clauderooks"
    alarm_error_threshold     = 10
    cloudtrail_retention_days = 30
    alarm_sns_topic_arn       = "arn:aws:sns:us-east-1:123456789012:clauderooks-dev-alerts"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.bedrock_errors.threshold == 10
    error_message = "CloudWatch alarm threshold should match var.alarm_error_threshold (10)"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.bedrock_errors.comparison_operator == "GreaterThanOrEqualToThreshold"
    error_message = "CloudWatch alarm should use GreaterThanOrEqualToThreshold comparison"
  }
}

# --- Test: CloudWatch alarm sends to the correct SNS topic ---
# Validates: Requirement 7.7 — Alarm sends notification to configurable SNS topic
run "alarm_sends_to_correct_sns_topic" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      id   = "us-east-1"
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.cloudtrail_bucket
    values = {
      json = "{}"
    }
  }

  variables {
    environment               = "dev"
    project_name              = "clauderooks"
    alarm_error_threshold     = 10
    cloudtrail_retention_days = 30
    alarm_sns_topic_arn       = "arn:aws:sns:us-east-1:123456789012:clauderooks-dev-alerts"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = contains(aws_cloudwatch_metric_alarm.bedrock_errors.alarm_actions, "arn:aws:sns:us-east-1:123456789012:clauderooks-dev-alerts")
    error_message = "CloudWatch alarm actions should include the configured SNS topic ARN"
  }

  assert {
    condition     = contains(aws_cloudwatch_metric_alarm.bedrock_errors.ok_actions, "arn:aws:sns:us-east-1:123456789012:clauderooks-dev-alerts")
    error_message = "CloudWatch alarm OK actions should include the configured SNS topic ARN"
  }
}

# --- Test: CloudTrail S3 bucket lifecycle uses configurable retention ---
# Validates: Requirement 7.5 — CloudTrail log retention with configurable retention period in days
run "cloudtrail_retention_uses_configurable_days" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      id   = "us-east-1"
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.cloudtrail_bucket
    values = {
      json = "{}"
    }
  }

  variables {
    environment               = "dev"
    project_name              = "clauderooks"
    alarm_error_threshold     = 10
    cloudtrail_retention_days = 30
    alarm_sns_topic_arn       = "arn:aws:sns:us-east-1:123456789012:clauderooks-dev-alerts"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.cloudtrail.rule[0].expiration[0].days == 30
    error_message = "CloudTrail S3 bucket lifecycle expiration should match var.cloudtrail_retention_days (30)"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.cloudtrail.rule[0].status == "Enabled"
    error_message = "CloudTrail S3 bucket lifecycle rule should be enabled"
  }
}

# --- Test: CloudTrail trail is created with correct naming ---
# Validates: Requirement 7.3 — CloudTrail trail captures Bedrock API calls
run "cloudtrail_created_with_correct_name" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      id   = "us-east-1"
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.cloudtrail_bucket
    values = {
      json = "{}"
    }
  }

  variables {
    environment               = "dev"
    project_name              = "clauderooks"
    alarm_error_threshold     = 10
    cloudtrail_retention_days = 30
    alarm_sns_topic_arn       = "arn:aws:sns:us-east-1:123456789012:clauderooks-dev-alerts"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_cloudtrail.bedrock.name == "clauderooks-dev-bedrock-trail"
    error_message = "CloudTrail trail name should follow the naming convention: clauderooks-dev-bedrock-trail"
  }

  assert {
    condition     = aws_cloudtrail.bedrock.enable_logging == true
    error_message = "CloudTrail trail should have logging enabled"
  }
}

# --- Test: Dashboard is created with correct naming ---
# Validates: Requirement 7.1 — CloudWatch dashboard displaying Bedrock API invocation metrics
run "dashboard_created_with_correct_name" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      id   = "us-east-1"
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.cloudtrail_bucket
    values = {
      json = "{}"
    }
  }

  variables {
    environment               = "dev"
    project_name              = "clauderooks"
    alarm_error_threshold     = 10
    cloudtrail_retention_days = 30
    alarm_sns_topic_arn       = "arn:aws:sns:us-east-1:123456789012:clauderooks-dev-alerts"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_cloudwatch_dashboard.bedrock.dashboard_name == "clauderooks-dev-bedrock-dashboard"
    error_message = "Dashboard name should follow the naming convention: clauderooks-dev-bedrock-dashboard"
  }
}
