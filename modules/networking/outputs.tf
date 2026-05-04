# =============================================================================
# Networking Module — Outputs
# =============================================================================
# Exposes VPC, subnet, and VPC endpoint identifiers for use by other modules
# and the root module.
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "bedrock_runtime_endpoint_id" {
  description = "ID of the Bedrock runtime VPC endpoint"
  value       = try(aws_vpc_endpoint.bedrock_runtime[0].id, "")
}

output "bedrock_control_endpoint_id" {
  description = "ID of the Bedrock control plane VPC endpoint"
  value       = try(aws_vpc_endpoint.bedrock_control[0].id, "")
}
