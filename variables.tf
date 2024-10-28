variable "search_services" {
  description = "The search services to make"
  type = list(object({
    name                                     = string
    rg_name                                  = string
    location                                 = optional(string, "uksouth")
    tags                                     = map(string)
    sku                                      = string
    allowed_ips                              = optional(list(string))
    authentication_failure_mode              = optional(string, "http403")
    customer_managed_key_enforcement_enabled = optional(bool)
    hosting_mode                             = optional(string, "default")
    identity_ids                             = optional(list(string))
    identity_type                            = optional(string)
    local_authentication_enabled             = optional(bool)
    partition_count                          = optional(number)
    public_network_access_enabled            = optional(bool)
    replica_count                            = optional(number)
    semantic_search_sku                      = optional(string)
  }))
}
