# =============================================================================
# Networking Module — VPC, Subnets, Security Groups, and VPC Endpoints
# =============================================================================
# Creates VPC infrastructure and optional VPC endpoints for private Bedrock
# access. Endpoints are conditionally created based on enable_vpc_endpoints.
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# -----------------------------------------------------------------------------
# Private Subnets (Multi-AZ — at least 2 AZs)
# -----------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-private-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "private"
  })
}

# -----------------------------------------------------------------------------
# Security Group for VPC Endpoints (HTTPS inbound from VPC CIDR)
# -----------------------------------------------------------------------------

resource "aws_security_group" "endpoint" {
  name        = "${local.name_prefix}-endpoint-sg"
  description = "Security group for VPC endpoints - allows HTTPS inbound from VPC CIDR"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-endpoint-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.endpoint.id
  description       = "Allow HTTPS inbound from VPC CIDR"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-endpoint-https-ingress"
  })
}

# -----------------------------------------------------------------------------
# VPC Endpoint Policy — restricts access to the dedicated IAM role only
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "endpoint_policy" {
  statement {
    sid       = "AllowBedrockAccessForRole"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [var.iam_role_arn]
    }
  }
}

# -----------------------------------------------------------------------------
# Bedrock Runtime VPC Endpoint (conditional)
# com.amazonaws.{region}.bedrock-runtime — Interface type
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "bedrock_runtime" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoint.id]

  policy = data.aws_iam_policy_document.endpoint_policy.json

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-bedrock-runtime-endpoint"
  })
}

# -----------------------------------------------------------------------------
# Bedrock Control Plane VPC Endpoint (conditional)
# com.amazonaws.{region}.bedrock — Interface type
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "bedrock_control" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.bedrock"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoint.id]

  policy = data.aws_iam_policy_document.endpoint_policy.json

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-bedrock-control-endpoint"
  })
}
