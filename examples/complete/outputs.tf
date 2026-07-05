output "search_service_ids" {
  description = "Map of service name to resource id."
  value       = module.search_service.ids
}

output "endpoints" {
  description = "Map of service name to its search endpoint URL."
  value       = module.search_service.endpoints
}

output "identities" {
  description = "Map of service name to its managed identity principal/tenant ids."
  value       = module.search_service.identities
}

output "shared_private_link_statuses" {
  description = "Map of \"<service>/<link>\" to its private connection status."
  value       = module.search_service.shared_private_link_statuses
}
