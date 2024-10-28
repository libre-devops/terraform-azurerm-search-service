```hcl
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
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_search_service.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/search_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_search_services"></a> [search\_services](#input\_search\_services) | The search services to make | <pre>list(object({<br>    name                                     = string<br>    rg_name                                  = string<br>    location                                 = optional(string, "uksouth")<br>    tags                                     = map(string)<br>    sku                                      = string<br>    allowed_ips                              = optional(list(string))<br>    authentication_failure_mode              = optional(string, "http403")<br>    customer_managed_key_enforcement_enabled = optional(bool)<br>    hosting_mode                             = optional(string, "default")<br>    identity_ids                             = optional(list(string))<br>    identity_type                            = optional(string)<br>    local_authentication_enabled             = optional(bool)<br>    partition_count                          = optional(number)<br>    public_network_access_enabled            = optional(bool)<br>    replica_count                            = optional(number)<br>    semantic_search_sku                      = optional(string)<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_search_service_identity_principal_ids"></a> [search\_service\_identity\_principal\_ids](#output\_search\_service\_identity\_principal\_ids) | The Principal IDs associated with the Managed Service Identities of all Search Service instances. |
| <a name="output_search_service_identity_tenant_ids"></a> [search\_service\_identity\_tenant\_ids](#output\_search\_service\_identity\_tenant\_ids) | The Tenant IDs associated with the Managed Service Identities of all Search Service instances. |
| <a name="output_search_service_ids"></a> [search\_service\_ids](#output\_search\_service\_ids) | The IDs of all the Search Service instances. |
| <a name="output_search_service_primary_keys"></a> [search\_service\_primary\_keys](#output\_search\_service\_primary\_keys) | The Primary Keys used for Search Service Administration. |
| <a name="output_search_service_query_keys"></a> [search\_service\_query\_keys](#output\_search\_service\_query\_keys) | The Query Keys of all Search Service instances. |
| <a name="output_search_service_secondary_keys"></a> [search\_service\_secondary\_keys](#output\_search\_service\_secondary\_keys) | The Secondary Keys used for Search Service Administration. |
