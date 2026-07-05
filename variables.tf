variable "search_services" {
  description = <<-EOT
    Azure AI Search services to create, keyed by service name. Secure defaults, all overridable:
      - local_authentication_enabled = false   (Entra ID / RBAC only, admin and query API keys off)
      - public_network_access_enabled = false   (no public endpoint; pair with a private endpoint, or
                                                set true with an allowed_ips allow-list)
      - identity.type = SystemAssigned          (so the service can pull from data sources, such as a
                                                Storage account or a Cognitive Services account, using
                                                its managed identity rather than a key)

    Per-service fields:
      sku                                       basic, standard, standard2, standard3,
                                                storage_optimized_l1/l2, or free.
      partition_count / replica_count           Scale out storage and query throughput.
      hosting_mode                              default, or highDensity (standard3 only).
      semantic_search_sku                       free or standard to enable semantic ranking.
      network_rule_bypass_option                None (default) or AzureServices to let trusted Azure
                                                services reach the service.
      allowed_ips                               Inbound IPv4 addresses / CIDRs allowed when public
                                                access is enabled.
      authentication_failure_mode               http401WithBearerChallenge or http403 (only meaningful
                                                when local authentication is enabled).
      customer_managed_key_enforcement_enabled  Require all indexes / synonym maps to use a CMK.
      identity                                  Managed identity (SystemAssigned by default).
      shared_private_links                      The service's outbound private connections to data
                                                sources, keyed by connection name. Each has a
                                                subresource_name (for example "blob" for a Storage
                                                account, "openai_account" for an Azure OpenAI /
                                                cognitive account, "vault" for Key Vault) and a
                                                target_resource_id. This is how the service indexes
                                                private data and reaches a private model for
                                                integrated vectorization without a public path; the
                                                connection is created pending the target owner's
                                                approval.
  EOT
  type = map(object({
    sku                                      = optional(string, "basic")
    local_authentication_enabled             = optional(bool, false)
    authentication_failure_mode              = optional(string)
    public_network_access_enabled            = optional(bool, false)
    allowed_ips                              = optional(list(string), [])
    network_rule_bypass_option               = optional(string)
    partition_count                          = optional(number, 1)
    replica_count                            = optional(number, 1)
    hosting_mode                             = optional(string, "default")
    semantic_search_sku                      = optional(string)
    customer_managed_key_enforcement_enabled = optional(bool)

    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string))
    }), {})

    shared_private_links = optional(map(object({
      subresource_name   = string
      target_resource_id = string
      request_message    = optional(string, "Managed by Terraform")
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in values(var.search_services) : contains([
        "free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2",
      ], s.sku)
    ])
    error_message = "Each search service sku must be free, basic, standard, standard2, standard3, storage_optimized_l1, or storage_optimized_l2."
  }

  validation {
    condition = alltrue([
      for s in values(var.search_services) :
      s.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], s.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned, or \"SystemAssigned, UserAssigned\"."
  }

  validation {
    condition = alltrue([
      for s in values(var.search_services) : contains(["default", "highDensity"], s.hosting_mode)
    ])
    error_message = "hosting_mode must be default or highDensity (highDensity requires the standard3 sku)."
  }

  validation {
    condition = alltrue([
      for s in values(var.search_services) : s.hosting_mode != "highDensity" || s.sku == "standard3"
    ])
    error_message = "hosting_mode = highDensity is only supported on the standard3 sku."
  }

  validation {
    condition = alltrue([
      for s in values(var.search_services) :
      s.semantic_search_sku == null ? true : contains(["free", "standard"], s.semantic_search_sku)
    ])
    error_message = "semantic_search_sku must be free or standard when set."
  }

  validation {
    condition = alltrue([
      for s in values(var.search_services) :
      s.network_rule_bypass_option == null ? true : contains(["None", "AzureServices"], s.network_rule_bypass_option)
    ])
    error_message = "network_rule_bypass_option must be None or AzureServices when set."
  }
}

variable "location" {
  description = "Azure region for the search services."
  type        = string
}

variable "resource_group_id" {
  description = "Resource id of the resource group to create the search services in. The name and subscription are parsed from it (pass the rg module's ids output)."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group id of the form /subscriptions/<sub>/resourceGroups/<name>."
  }
}

variable "tags" {
  description = "Tags to apply to the search services."
  type        = map(string)
  default     = {}
}
