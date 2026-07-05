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
