# clauderocks

Terraform infrastructure-as-code project that provisions all AWS resources required to run [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) backed by [Amazon Bedrock](https://aws.amazon.com/bedrock/).

clauderocks creates a complete, production-ready setup: IAM users and roles with least-privilege access, Secrets Manager for credential storage, optional VPC endpoints for private Bedrock connectivity, CloudWatch monitoring, CloudTrail audit logging, budget alerts, and remote state management — all organized into composable Terraform modules with multi-environment support (dev, staging, prod).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installing Claude Code CLI](#installing-claude-code-cli)
- [Deploying Infrastructure](#deploying-infrastructure)
- [Activating Bedrock Model Access](#activating-bedrock-model-access)
- [Configuring Claude Code with Bedrock](#configuring-claude-code-with-bedrock)
- [Retrieving IAM Credentials from Secrets Manager](#retrieving-iam-credentials-from-secrets-manager)
- [Assuming the IAM Role](#assuming-the-iam-role)
- [Required Environment Variables](#required-environment-variables)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Environments](#environments)
- [Tearing Down Infrastructure](#tearing-down-infrastructure)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before getting started, ensure you have the following installed and configured:

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.6.0 | Infrastructure provisioning |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | v2 | AWS credential management and Secrets Manager access |
| [Node.js](https://nodejs.org/) | >= 18 | Required for Claude Code CLI |
| [npm](https://www.npmjs.com/) | (bundled with Node.js) | Package manager for CLI installation |

You also need:

- An **AWS account** with permissions to create IAM users, roles, policies, S3 buckets, DynamoDB tables, Secrets Manager secrets, CloudWatch resources, CloudTrail trails, and Budgets.
- AWS CLI **configured** with credentials that have sufficient permissions to deploy the infrastructure:

```bash
aws configure
```

## Installing Claude Code CLI

Install the Claude Code CLI globally via npm:

```bash
npm install -g @anthropic-ai/claude-code
```

Verify the installation:

```bash
claude --version
```

> **Note:** Claude Code CLI requires Node.js 18 or later. If you have an older version, upgrade Node.js before installing.

## Deploying Infrastructure

1. **Clone the repository** and navigate to the project directory:

```bash
cd clauderocks
```

2. **Initialize Terraform** (use `-backend=false` for first-time setup before the state backend exists):

```bash
terraform init -backend=false
```

3. **Review and apply** for your target environment:

```bash
# Dev environment
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# Staging environment
terraform plan -var-file=envs/staging.tfvars
terraform apply -var-file=envs/staging.tfvars

# Production environment
terraform plan -var-file=envs/prod.tfvars
terraform apply -var-file=envs/prod.tfvars
```

After the initial apply creates the state backend resources, configure the S3 backend in `backend.tf` (replace `{environment}` with your target environment, e.g., `dev`) and re-initialize with `terraform init -migrate-state` to migrate state to remote storage.

## Activating Bedrock Model Access

Anthropic Claude models on Bedrock require an AWS Marketplace subscription. This is a **one-time step per AWS account** — it costs nothing and persists even if you destroy and recreate the infrastructure.

After deploying, run the following command using your **admin/root credentials** (the same credentials you used to run `terraform apply`):

```bash
aws bedrock-runtime converse \
  --model-id us.anthropic.claude-sonnet-4-20250514-v1:0 \
  --region us-east-1 \
  --messages '[{"role":"user","content":[{"text":"hi"}]}]'
```

If you get a response from Claude, the marketplace subscription is active and you can proceed.

> **Note:** Newer Claude models on Bedrock use **inference profiles** instead of direct model IDs. Inference profile IDs are prefixed with `us.` or `global.` (e.g., `us.anthropic.claude-sonnet-4-20250514-v1:0`). You can list available profiles with:
>
> ```bash
> aws bedrock list-inference-profiles \
>   --region us-east-1 \
>   --query "inferenceProfileSummaries[?contains(inferenceProfileId,'anthropic')].{id:inferenceProfileId,name:inferenceProfileName}" \
>   --output table
> ```

## Configuring Claude Code with Bedrock

Claude Code CLI uses Amazon Bedrock as its backend when the `CLAUDE_CODE_USE_BEDROCK` environment variable is set. You need two things:

1. The **Bedrock backend flag** enabled
2. The **AWS region** where Bedrock models are available

Set these environment variables:

```bash
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1
```

With these set, Claude Code CLI routes all model requests through Amazon Bedrock instead of the Anthropic API.

## Retrieving IAM Credentials from Secrets Manager

clauderocks stores IAM access keys in AWS Secrets Manager. The secret is named using the pattern `clauderocks-{env}/claude-code-keys` (e.g., `clauderocks-dev/claude-code-keys`).

Retrieve the credentials using the AWS CLI:

```bash
aws secretsmanager get-secret-value \
  --secret-id "clauderocks-dev/claude-code-keys" \
  --region us-east-1 \
  --query 'SecretString' \
  --output text | jq .
```

This returns a JSON object with two fields:

```json
{
  "access_key_id": "AKIA...",
  "secret_access_key": "..."
}
```

To extract and export the values directly:

```bash
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "clauderocks-dev/claude-code-keys" \
  --region us-east-1 \
  --query 'SecretString' \
  --output text)

export AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.access_key_id')
export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.secret_access_key')

```

> **Security note:** These credentials belong to the IAM user, which only has permission to assume the Bedrock access role. You must assume the role (next step) before making Bedrock API calls.

## Assuming the IAM Role

The IAM user created by clauderocks has a single permission: assuming the Bedrock access role. The role carries the actual Bedrock permissions.

Assume the role using the AWS CLI:

```bash
ROLE_OUTPUT=$(aws sts assume-role \
  --role-arn "arn:aws:iam::<ACCOUNT_ID>:role/clauderocks-dev-bedrock-access" \
  --role-session-name "claude-code-session" \
  --duration-seconds 3600)

export AWS_ACCESS_KEY_ID=$(echo "$ROLE_OUTPUT" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$ROLE_OUTPUT" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$ROLE_OUTPUT" | jq -r '.Credentials.SessionToken')
```

Replace `<ACCOUNT_ID>` with your AWS account ID. The role ARN follows the pattern `arn:aws:iam::<ACCOUNT_ID>:role/clauderocks-{env}-bedrock-access`.

You can find the exact role ARN from the Terraform output:

```bash
terraform output iam_role_arn
```

> **Note:** Role sessions expire after the configured `max_session_duration` (default: 3600 seconds / 1 hour). You need to re-assume the role when the session expires.

## Required Environment Variables

The following environment variables must be set for Claude Code CLI to work with the Bedrock backend:

| Variable | Required | Description |
|----------|----------|-------------|
| `CLAUDE_CODE_USE_BEDROCK` | Yes | Set to `1` to enable the Bedrock backend |
| `AWS_REGION` | Yes | AWS region where Bedrock is available (e.g., `us-east-1`) |
| `AWS_ACCESS_KEY_ID` | Yes | Access key from the assumed role session |
| `AWS_SECRET_ACCESS_KEY` | Yes | Secret key from the assumed role session |
| `AWS_SESSION_TOKEN` | Yes | Session token from the assumed role session |

> **Important:** The `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` values should come from the **assumed role session** (via `aws sts assume-role`), not directly from the IAM user credentials stored in Secrets Manager.

## Quick Start

Complete workflow from deployment to running Claude Code:

```bash
# 1. Deploy infrastructure
cd clauderocks
terraform init -backend=false
terraform apply -var-file=envs/dev.tfvars

# 2. Activate Bedrock model access (one-time per AWS account)
#    Run this with your admin/root credentials.
aws bedrock-runtime converse \
  --model-id us.anthropic.claude-sonnet-4-20250514-v1:0 \
  --region us-east-1 \
  --messages '[{"role":"user","content":[{"text":"hi"}]}]'

# 3. Retrieve IAM credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "clauderocks-dev/claude-code-keys" \
  --region us-east-1 \
  --query 'SecretString' \
  --output text)

export AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.access_key_id')
export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.secret_access_key')
unset AWS_SESSION_TOKEN

# 4. Assume the Bedrock access role
ROLE_OUTPUT=$(aws sts assume-role \
  --role-arn "$(terraform output -raw iam_role_arn)" \
  --role-session-name "claude-code-session")

export AWS_ACCESS_KEY_ID=$(echo "$ROLE_OUTPUT" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$ROLE_OUTPUT" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$ROLE_OUTPUT" | jq -r '.Credentials.SessionToken')

# 5. Configure Bedrock backend
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1

# 6. Run Claude Code
claude
```

## Project Structure

```
clauderocks/
├── main.tf                     # Root module — orchestrates all child modules
├── variables.tf                # Root input variables
├── outputs.tf                  # Root outputs
├── versions.tf                 # Terraform and provider version constraints
├── providers.tf                # Provider configuration
├── locals.tf                   # Common locals (tags, naming)
├── envs/
│   ├── dev.tfvars              # Dev environment variables
│   ├── staging.tfvars          # Staging environment variables
│   └── prod.tfvars             # Prod environment variables
├── modules/
│   ├── state-backend/          # S3 + DynamoDB for remote state
│   ├── iam/                    # IAM user, role, policy, Secrets Manager
│   ├── bedrock/                # Bedrock model access configuration
│   ├── networking/             # VPC and VPC endpoints (optional)
│   ├── monitoring/             # CloudWatch dashboards, alarms, CloudTrail
│   └── budget/                 # AWS Budgets and SNS alerts
├── tests/                      # Terraform test files
├── docs/                       # Project documentation (README, HLD, LLD)
└── .github/workflows/          # CI/CD pipelines
```

## Environments

clauderocks supports three isolated environments, each with its own state file, resource naming, and configuration:

| Environment | VPC Endpoints | Budget Limit | Use Case |
|-------------|--------------|--------------|----------|
| `dev` | Disabled | $50/month | Development and experimentation |
| `staging` | Disabled | $100/month | Pre-production testing |
| `prod` | Enabled | $500/month | Production workloads |

Select an environment by passing the corresponding `-var-file`:

```bash
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```

All resources are tagged with the environment name and use the naming pattern `clauderocks-{env}-*` to prevent collisions.

## Tearing Down Infrastructure

To completely remove all clauderocks resources from your AWS account:

1. **Switch to your admin/root credentials** (the same ones used for `terraform apply`):

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

2. **Empty the S3 buckets.** Terraform cannot delete non-empty buckets. The CloudTrail bucket and the state bucket (which has versioning enabled) must be emptied first:

```bash
# Empty and remove the CloudTrail logs bucket
aws s3 rb s3://clauderocks-dev-cloudtrail-logs --force --region us-east-1

# Empty the versioned state bucket (must delete all object versions)
aws s3api list-object-versions \
  --bucket clauderocks-tfstate-dev \
  --region us-east-1 \
  --output json | \
jq '{Objects: [(.Versions // [])[], (.DeleteMarkers // [])[]] | map({Key, VersionId})}' | \
aws s3api delete-objects \
  --bucket clauderocks-tfstate-dev \
  --region us-east-1 \
  --delete file:///dev/stdin

aws s3 rb s3://clauderocks-tfstate-dev --region us-east-1
```

3. **Destroy the remaining resources:**

```bash
terraform destroy -var-file=envs/dev.tfvars
```

Replace `dev` with `staging` or `prod` as needed. Repeat for each environment you deployed.

> **Note:** The AWS Marketplace subscription for Anthropic models is account-level and is not removed by `terraform destroy`. It costs nothing to leave active. To cancel it manually, visit the [AWS Marketplace subscriptions console](https://console.aws.amazon.com/marketplace/home#/subscriptions).

## Troubleshooting

### AccessDeniedException

**Symptom:** Claude Code returns an error like:

```
An error occurred (AccessDeniedException) when calling the InvokeModel operation:
User: arn:aws:iam::123456789012:user/claude-code-dev is not authorized to perform: bedrock:InvokeModel
```

**Cause:** You are using the IAM user credentials directly instead of the assumed role credentials. The IAM user only has permission to assume the role — Bedrock access is attached to the role.

**Fix:**
1. Assume the IAM role first (see [Assuming the IAM Role](#assuming-the-iam-role))
2. Verify you exported `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` from the `assume-role` output
3. Confirm the active identity:

```bash
aws sts get-caller-identity
```

The ARN should show `assumed-role/clauderocks-{env}-bedrock-access`, not the IAM user.

### ModelNotAvailableException

**Symptom:**

```
An error occurred (ModelNotAvailableException) when calling the InvokeModel operation:
The model is not available in this region.
```

**Cause:** The requested Claude model has not been enabled in your AWS account for the target region, or you are targeting a region where the model is not offered.

**Fix:**
1. Open the [Amazon Bedrock console](https://console.aws.amazon.com/bedrock/) in your target region
2. Navigate to **Model access** and request access to the Anthropic Claude models you need
3. Wait for the access request to be approved (usually immediate for most models)
4. Verify `AWS_REGION` is set to a region that supports the model (default: `us-east-1`)
5. Check that `bedrock_model_ids` in your `.tfvars` file matches the models you have access to

### ThrottlingException

**Symptom:**

```
An error occurred (ThrottlingException) when calling the InvokeModel operation:
Too many requests, please wait before trying again.
```

**Cause:** You have exceeded the Bedrock API rate limits for your account or the specific model.

**Fix:**
1. Wait a few seconds and retry — Bedrock applies per-model rate limits
2. If persistent, request a quota increase through the [AWS Service Quotas console](https://console.aws.amazon.com/servicequotas/)
3. Check the CloudWatch dashboard (provisioned by clauderocks) for invocation patterns:

```bash
terraform output dashboard_arn
```

4. Consider distributing load across multiple models if available in your environment

### VPC Endpoint Connectivity Issues

**Symptom:** Bedrock API calls time out or fail with connection errors when VPC endpoints are enabled.

**Cause:** Security group rules, route tables, or DNS resolution may be misconfigured for the VPC endpoints.

**Fix:**
1. Verify VPC endpoints are in the `available` state:

```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'VpcEndpoints[].{Id:VpcEndpointId,Service:ServiceName,State:State}'
```

2. Confirm the security group allows HTTPS (port 443) inbound from your subnets
3. Verify DNS resolution is working — VPC endpoints require `EnableDnsSupport` and `EnableDnsHostnames` on the VPC
4. Check that the VPC endpoint policy allows the IAM role:

```bash
aws ec2 describe-vpc-endpoints \
  --vpc-endpoint-ids <endpoint-id> \
  --query 'VpcEndpoints[].PolicyDocument'
```

5. If using the endpoint from outside the VPC (e.g., local development), disable VPC endpoints (`enable_vpc_endpoints = false`) and use the public Bedrock endpoint instead

### Expired Session Token

**Symptom:**

```
An error occurred (ExpiredTokenException) when calling the InvokeModel operation:
The security token included in the request is expired.
```

**Cause:** The assumed role session has expired. The default session duration is 3600 seconds (1 hour).

**Fix:**
1. Re-assume the role to get fresh credentials (see [Assuming the IAM Role](#assuming-the-iam-role))
2. If you need longer sessions, increase `max_session_duration` in your `.tfvars` file (maximum: 43200 seconds / 12 hours)

### Secrets Manager Access Denied

**Symptom:** Unable to retrieve credentials from Secrets Manager.

**Fix:**
1. Ensure your AWS CLI is configured with credentials that have `secretsmanager:GetSecretValue` permission
2. Verify the secret name matches the expected pattern:

```bash
aws secretsmanager list-secrets \
  --filters Key=name,Values=clauderocks \
  --query 'SecretList[].Name'
```

3. Check that the secret exists in the correct region

### AWS Marketplace Access Denied

**Symptom:**

```
An error occurred (AccessDeniedException) when calling the InvokeModel operation:
Model access is denied due to IAM user or service role is not authorized to perform
the required AWS Marketplace actions (aws-marketplace:ViewSubscriptions, aws-marketplace:Subscribe)
```

**Cause:** Anthropic models on Bedrock require an AWS Marketplace subscription. This must be triggered once per AWS account using admin/root credentials before the IAM role can invoke models.

**Fix:**
1. Switch to your admin/root credentials (unset any assumed role credentials):

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

2. Invoke any Claude model once to trigger the marketplace subscription:

```bash
aws bedrock-runtime converse \
  --model-id us.anthropic.claude-sonnet-4-20250514-v1:0 \
  --region us-east-1 \
  --messages '[{"role":"user","content":[{"text":"hi"}]}]'
```

3. After getting a successful response, re-assume the IAM role and retry. This is a one-time step per AWS account.
