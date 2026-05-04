# =============================================================================
# Terraform S3 Backend Configuration
# =============================================================================
#
# This file configures remote state storage using S3 with DynamoDB locking.
# The backend block is COMMENTED OUT by default so that the initial
# `terraform init` works with local state before the S3 bucket and DynamoDB
# table exist.
#
# -----------------------------------------------------------------------------
# Bootstrap Procedure
# -----------------------------------------------------------------------------
#
# Follow these steps to initialize the remote backend for a given environment:
#
#   1. Initialize with local state (backend block stays commented out):
#
#        terraform init
#
#   2. Apply ONLY the state-backend module to create the S3 bucket and
#      DynamoDB table:
#
#        terraform apply -target=module.state_backend -var-file=envs/<env>.tfvars
#
#   3. Uncomment the backend block below and replace {environment} with the
#      target environment name (dev, staging, or prod).
#
#   4. Re-initialize Terraform to migrate local state to the new S3 backend:
#
#        terraform init -migrate-state
#
#      Terraform will prompt you to confirm the migration. Type "yes".
#
#   5. After migration, all subsequent commands use the remote backend
#      automatically.
#
# -----------------------------------------------------------------------------
# Per-Environment Values
# -----------------------------------------------------------------------------
#
#   Environment | S3 Bucket                      | DynamoDB Table
#   ----------- | ------------------------------ | ----------------------------
#   dev         | clauderooks-tfstate-dev         | clauderooks-tflock-dev
#   staging     | clauderooks-tfstate-staging     | clauderooks-tflock-staging
#   prod        | clauderooks-tfstate-prod        | clauderooks-tflock-prod
#
# The state key is always "terraform.tfstate" and the region defaults to
# us-east-1 to match the provider configuration.
#
# =============================================================================

# Uncomment the block below after the state-backend module has been applied.
# Replace {environment} with: dev, staging, or prod.
#
# terraform {
#   backend "s3" {
#     bucket         = "clauderooks-tfstate-{environment}"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "clauderooks-tflock-{environment}"
#     encrypt        = true
#   }
# }
