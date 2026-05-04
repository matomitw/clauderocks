# State Backend Module Tests
# Validates: Requirements 1.1, 1.3, 1.4, 17.1

provider "aws" {
  region = "us-east-1"

  # Use mock/plan-only — no real AWS resources needed
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# --- Test: S3 bucket naming convention ---
# Validates: Requirement 1.1 — S3 bucket provisioned for state storage
run "s3_bucket_naming_convention" {
  command = plan

  module {
    source = "./modules/state-backend"
  }

  variables {
    environment  = "dev"
    project_name = "clauderocks"
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_s3_bucket.state.bucket == "clauderocks-tfstate-dev"
    error_message = "S3 bucket name should follow the pattern {project_name}-tfstate-{environment}"
  }
}

# --- Test: S3 bucket versioning enabled ---
# Validates: Requirement 1.1 — versioning enabled on state bucket
run "s3_bucket_versioning_enabled" {
  command = plan

  module {
    source = "./modules/state-backend"
  }

  variables {
    environment  = "dev"
    project_name = "clauderocks"
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning must be enabled"
  }
}

# --- Test: S3 bucket server-side encryption with AES-256 ---
# Validates: Requirement 1.3 — server-side encryption on state bucket
run "s3_bucket_encryption_aes256" {
  command = plan

  module {
    source = "./modules/state-backend"
  }

  variables {
    environment  = "dev"
    project_name = "clauderocks"
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = [for r in aws_s3_bucket_server_side_encryption_configuration.state.rule : [for d in r.apply_server_side_encryption_by_default : d.sse_algorithm][0]][0] == "AES256"
    error_message = "S3 bucket must use AES-256 server-side encryption"
  }
}

# --- Test: S3 bucket public access block — all four settings enabled ---
# Validates: Requirement 1.4 — block all public access on state bucket
run "s3_bucket_public_access_blocked" {
  command = plan

  module {
    source = "./modules/state-backend"
  }

  variables {
    environment  = "dev"
    project_name = "clauderocks"
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls == true
    error_message = "block_public_acls must be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_policy == true
    error_message = "block_public_policy must be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.ignore_public_acls == true
    error_message = "ignore_public_acls must be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.restrict_public_buckets == true
    error_message = "restrict_public_buckets must be true"
  }
}

# --- Test: DynamoDB table has correct hash key ---
# Validates: Requirement 1.1 — DynamoDB table for state locking
run "dynamodb_lock_table_hash_key" {
  command = plan

  module {
    source = "./modules/state-backend"
  }

  variables {
    environment  = "dev"
    project_name = "clauderocks"
    tags = {
      Project     = "clauderocks"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "test"
    }
  }

  assert {
    condition     = aws_dynamodb_table.lock.hash_key == "LockID"
    error_message = "DynamoDB lock table must use LockID as the hash key"
  }

  assert {
    condition     = aws_dynamodb_table.lock.name == "clauderocks-tflock-dev"
    error_message = "DynamoDB table name should follow the pattern {project_name}-tflock-{environment}"
  }
}
