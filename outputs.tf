output "definition" {
  value       = local.container_definition
  description = "Single container definition which can be composed for more complex tasks"
}

output "container_name" {
  value       = var.container_name
  description = "Container name"
}

output "service_type" {
  value       = var.service_type
  description = "Container service type"
}

output "ports" {
  value       = local.ports
  description = "Container ports for use in load balancer configs"
}

output "shared_data" {
  value = try((var.shared_data == null ? [] : [merge(
    var.shared_data,
    { volume = local.shared_data_volume }
  )])[0], null)
}

output "secrets" {
  value       = var.secrets
  description = "The secrets input, passed through so other container definitions can reuse the mapping"
}

output "secret_arns" {
  value       = var.secrets == null ? [] : [var.secrets.arn]
  description = "ARNs of the secrets the definition reads, for the service's execution role"
}
