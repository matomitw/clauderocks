################################################################################
# Bedrock Module - Outputs
################################################################################

output "enabled_model_arns" {
  description = "ARNs of enabled Bedrock models"
  value       = values(local.model_arns)
}

output "model_access_status" {
  description = "Status of each model access request"
  value = {
    for model_id in var.model_ids :
    model_id => "ACCESS_REQUESTED"
  }
}
