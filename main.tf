# Azure AI Search services keyed by name, with secure defaults: Entra-only auth (API keys off), no
# public endpoint, and a system-assigned identity (so the service can pull from data sources such as
# Storage or a Cognitive Services account with a managed identity). The resource group is passed by
# id and parsed.
locals {
  rg                  = provider::azurerm::parse_resource_id(var.resource_group_id)
  resource_group_name = local.rg.resource_group_name
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
