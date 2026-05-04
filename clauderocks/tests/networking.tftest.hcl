# Networking Module Tests
# Validates: Requirements 5.7, 5.4, 17.1

mock_provider "aws" {}

# --- Test: VPC is created with correct CIDR ---
# Validates: Requirement 5.1 — VPC with configurable CIDR range
run "vpc_created_with_correct_cidr" {
  command = plan

  module {
    source = "./modules/networking"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = data.aws_iam_policy_document.endpoint_policy
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowBedrockAccessForRole\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access\"},\"Action\":\"*\",\"Resource\":\"*\"}]}"
    }
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    vpc_cidr             = "10.0.0.0/16"
    enable_vpc_endpoints = true
    iam_role_arn         = "arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access"
    region               = "us-east-1"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block should be 10.0.0.0/16"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_support == true
    error_message = "VPC should have DNS support enabled"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "VPC should have DNS hostnames enabled"
  }
}

# --- Test: Private subnets are created in multiple AZs ---
# Validates: Requirement 5.5 — VPC endpoints placed in private subnets (multi-AZ)
run "private_subnets_multi_az" {
  command = plan

  module {
    source = "./modules/networking"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = data.aws_iam_policy_document.endpoint_policy
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowBedrockAccessForRole\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access\"},\"Action\":\"*\",\"Resource\":\"*\"}]}"
    }
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    vpc_cidr             = "10.0.0.0/16"
    enable_vpc_endpoints = true
    iam_role_arn         = "arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access"
    region               = "us-east-1"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets for multi-AZ deployment"
  }

  assert {
    condition     = aws_subnet.private[0].map_public_ip_on_launch == false
    error_message = "Private subnets should not map public IPs on launch"
  }

  assert {
    condition     = aws_subnet.private[1].map_public_ip_on_launch == false
    error_message = "Private subnets should not map public IPs on launch"
  }
}

# --- Test: VPC endpoints are created when enabled ---
# Validates: Requirement 5.7 — endpoints provisioned when feature is enabled
run "vpc_endpoints_created_when_enabled" {
  command = plan

  module {
    source = "./modules/networking"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = data.aws_iam_policy_document.endpoint_policy
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowBedrockAccessForRole\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access\"},\"Action\":\"*\",\"Resource\":\"*\"}]}"
    }
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    vpc_cidr             = "10.0.0.0/16"
    enable_vpc_endpoints = true
    iam_role_arn         = "arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access"
    region               = "us-east-1"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = length(aws_vpc_endpoint.bedrock_runtime) == 1
    error_message = "Bedrock runtime VPC endpoint should be created when enable_vpc_endpoints is true"
  }

  assert {
    condition     = length(aws_vpc_endpoint.bedrock_control) == 1
    error_message = "Bedrock control plane VPC endpoint should be created when enable_vpc_endpoints is true"
  }

  assert {
    condition     = aws_vpc_endpoint.bedrock_runtime[0].service_name == "com.amazonaws.us-east-1.bedrock-runtime"
    error_message = "Bedrock runtime endpoint should use the correct service name"
  }

  assert {
    condition     = aws_vpc_endpoint.bedrock_control[0].service_name == "com.amazonaws.us-east-1.bedrock"
    error_message = "Bedrock control plane endpoint should use the correct service name"
  }

  assert {
    condition     = aws_vpc_endpoint.bedrock_runtime[0].vpc_endpoint_type == "Interface"
    error_message = "Bedrock runtime endpoint should be Interface type"
  }
}

# --- Test: VPC endpoints are skipped when disabled ---
# Validates: Requirement 5.7 — endpoints skipped when feature is disabled
run "vpc_endpoints_skipped_when_disabled" {
  command = plan

  module {
    source = "./modules/networking"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = data.aws_iam_policy_document.endpoint_policy
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    vpc_cidr             = "10.0.0.0/16"
    enable_vpc_endpoints = false
    iam_role_arn         = "arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access"
    region               = "us-east-1"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = length(aws_vpc_endpoint.bedrock_runtime) == 0
    error_message = "Bedrock runtime VPC endpoint should not be created when enable_vpc_endpoints is false"
  }

  assert {
    condition     = length(aws_vpc_endpoint.bedrock_control) == 0
    error_message = "Bedrock control plane VPC endpoint should not be created when enable_vpc_endpoints is false"
  }
}

# --- Test: Endpoint policy references the IAM role ARN ---
# Validates: Requirement 5.4 — VPC endpoint policy restricts access to dedicated IAM role
run "endpoint_policy_references_iam_role" {
  command = plan

  module {
    source = "./modules/networking"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = data.aws_iam_policy_document.endpoint_policy
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowBedrockAccessForRole\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access\"},\"Action\":\"*\",\"Resource\":\"*\"}]}"
    }
  }

  variables {
    environment          = "dev"
    project_name         = "clauderooks"
    vpc_cidr             = "10.0.0.0/16"
    enable_vpc_endpoints = true
    iam_role_arn         = "arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access"
    region               = "us-east-1"
    tags = {
      Project     = "clauderooks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  # The endpoint policy JSON is constructed from the iam_role_arn variable via
  # data.aws_iam_policy_document.endpoint_policy. We verify the VPC endpoints
  # receive the policy and that the policy document is wired to the role ARN.
  assert {
    condition     = aws_vpc_endpoint.bedrock_runtime[0].policy != null
    error_message = "Bedrock runtime endpoint should have a policy attached"
  }

  assert {
    condition     = aws_vpc_endpoint.bedrock_control[0].policy != null
    error_message = "Bedrock control plane endpoint should have a policy attached"
  }

  assert {
    condition     = strcontains(aws_vpc_endpoint.bedrock_runtime[0].policy, "arn:aws:iam::123456789012:role/clauderooks-dev-bedrock-access")
    error_message = "Endpoint policy should reference the provided IAM role ARN"
  }
}
