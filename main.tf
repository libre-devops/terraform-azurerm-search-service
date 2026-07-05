# Azure AI Search services keyed by name, with secure defaults: Entra-only auth (API keys off), no
# public endpoint, and a system-assigned identity (so the service can pull from data sources such as
# Storage or a Cognitive Services account with a managed identity). Each service can also own a set of
# shared private links: the service's own outbound private connections to data sources (a private
# Storage account to index, a private Azure OpenAI / cognitive account for integrated vectorization, a
# Key Vault, Cosmos, SQL), so private RAG works without any of them being public. The resource group
# is passed by id and parsed.
locals {
  rg                  = provider::azurerm::parse_resource_id(var.resource_group_id)
  resource_group_name = local.rg.resource_group_name

  # Flatten each service's shared private links to "<service>/<link>" keys.
  shared_private_links = merge([
    for svc_name, s in var.search_services : {
      for link_name, l in s.shared_private_links : "${svc_name}/${link_name}" => {
        service_name       = svc_name
        link_name          = link_name
        subresource_name   = l.subresource_name
        target_resource_id = l.target_resource_id
        request_message    = l.request_message
      }
    }
  ]...)
}

resource "azurerm_search_service" "this" {
  for_each = var.search_services

  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  name = each.key
  sku  = each.value.sku

  local_authentication_enabled             = each.value.local_authentication_enabled
  authentication_failure_mode              = each.value.authentication_failure_mode
  public_network_access_enabled            = each.value.public_network_access_enabled
  allowed_ips                              = each.value.allowed_ips
  network_rule_bypass_option               = each.value.network_rule_bypass_option
  partition_count                          = each.value.partition_count
  replica_count                            = each.value.replica_count
  hosting_mode                             = each.value.hosting_mode
  semantic_search_sku                      = each.value.semantic_search_sku
  customer_managed_key_enforcement_enabled = each.value.customer_managed_key_enforcement_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
}

# Shared private links: the search service's outbound private connections to data sources. Each one
# raises a private endpoint connection on the target (which the target owner then approves), so the
# service can reach a private Storage account, a private Azure OpenAI / cognitive account, Key Vault,
# Cosmos, or SQL without a public path.
resource "azurerm_search_shared_private_link_service" "this" {
  for_each = local.shared_private_links

  name               = each.value.link_name
  search_service_id  = azurerm_search_service.this[each.value.service_name].id
  subresource_name   = each.value.subresource_name
  target_resource_id = each.value.target_resource_id
  request_message    = each.value.request_message
}
