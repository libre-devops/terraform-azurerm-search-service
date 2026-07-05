output "ids" {
  description = "Map of service name to its resource id."
  value       = { for k, v in azurerm_search_service.this : k => v.id }
}

output "ids_zipmap" {
  description = "Map of service name to a { name, id } object, for passing where both are needed together."
  value       = { for k, v in azurerm_search_service.this : k => { name = v.name, id = v.id } }
}

output "names" {
  description = "The service names."
  value       = keys(azurerm_search_service.this)
}

output "endpoints" {
  description = "Map of service name to its search endpoint URL."
  value       = { for k, v in azurerm_search_service.this : k => "https://${v.name}.search.windows.net" }
}

output "identities" {
  description = "Map of service name to its managed identity { principal_id, tenant_id } (principal_id is populated for system-assigned identities)."
  value = {
    for k, v in azurerm_search_service.this : k => try({
      principal_id = v.identity[0].principal_id
      tenant_id    = v.identity[0].tenant_id
    }, null)
  }
}

output "primary_keys" {
  description = "Map of service name to its primary admin key (empty when local_authentication_enabled is false)."
  value       = { for k, v in azurerm_search_service.this : k => v.primary_key }
  sensitive   = true
}

output "secondary_keys" {
  description = "Map of service name to its secondary admin key (empty when local_authentication_enabled is false)."
  value       = { for k, v in azurerm_search_service.this : k => v.secondary_key }
  sensitive   = true
}

output "query_keys" {
  description = "Map of service name to its query keys (list of { name, key }; empty when local_authentication_enabled is false)."
  value       = { for k, v in azurerm_search_service.this : k => v.query_keys }
  sensitive   = true
}

output "shared_private_link_ids" {
  description = "Map of \"<service>/<link>\" to the shared private link resource id."
  value       = { for k, v in azurerm_search_shared_private_link_service.this : k => v.id }
}

output "shared_private_link_statuses" {
  description = "Map of \"<service>/<link>\" to the connection status (Pending until the target owner approves it)."
  value       = { for k, v in azurerm_search_shared_private_link_service.this : k => v.status }
}

output "resource_group_name" {
  description = "Resource group name parsed from resource_group_id."
  value       = local.resource_group_name
}

output "subscription_id" {
  description = "Subscription id parsed from resource_group_id."
  value       = local.rg.subscription_id
}

output "tags" {
  description = "The tags applied to the services."
  value       = var.tags
}
