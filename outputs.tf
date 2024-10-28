output "search_service_identity_principal_ids" {
  description = "The Principal IDs associated with the Managed Service Identities of all Search Service instances."
  value       = [for search in azurerm_search_service.this : search.identity[0].principal_id]
}

output "search_service_identity_tenant_ids" {
  description = "The Tenant IDs associated with the Managed Service Identities of all Search Service instances."
  value       = [for search in azurerm_search_service.this : search.identity[0].tenant_id]
}

output "search_service_ids" {
  description = "The IDs of all the Search Service instances."
  value       = [for search in azurerm_search_service.this : search.id]
}

output "search_service_primary_keys" {
  description = "The Primary Keys used for Search Service Administration."
  value       = [for search in azurerm_search_service.this : search.primary_key]
}

output "search_service_query_keys" {
  description = "The Query Keys of all Search Service instances."
  value = [for search in azurerm_search_service.this : {
    query_keys  = search.query_keys[*].key,
    query_names = search.query_keys[*].name
  }]
}

output "search_service_secondary_keys" {
  description = "The Secondary Keys used for Search Service Administration."
  value       = [for search in azurerm_search_service.this : search.secondary_key]
}
