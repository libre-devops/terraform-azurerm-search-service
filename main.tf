resource "azurerm_search_service" "this" {
  for_each                                 = { for instance in var.search_services : instance.name => instance }
  location                                 = each.value.location
  name                                     = each.value.name
  resource_group_name                      = each.value.rg_name
  sku                                      = lower(each.value.sku)
  allowed_ips                              = try(each.value.allowed_ips, [])
  authentication_failure_mode              = each.value.authentication_failure_mode
  customer_managed_key_enforcement_enabled = each.value.customer_managed_key_enforcement_enabled
  hosting_mode                             = each.value.hosting_mode
  local_authentication_enabled             = each.value.local_authentication_enabled
  partition_count                          = each.value.partition_count
  public_network_access_enabled            = each.value.public_network_access_enabled
  replica_count                            = each.value.replica_count
  semantic_search_sku                      = each.value.semantic_search_sku


  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned, UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = try(each.value.identity_ids, [])
    }
  }


  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }
}