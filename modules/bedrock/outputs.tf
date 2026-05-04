################################################################################
# Bedrock Module - Outputs
################################################################################

output "enabled_model_ids" {
  description = "Inference profile IDs of enabled Bedrock models"
  value       = var.model_ids
}
