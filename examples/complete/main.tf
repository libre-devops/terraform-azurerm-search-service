locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  srch_name = "srch-${var.short}-${var.loc}-${terraform.workspace}-002"
  sa_name   = "st${var.short}${var.loc}${terraform.workspace}002"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  environment     = "prd"
  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-search-service" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# A private data source for the search service to index over a shared private link.
module "storage" {
  source  = "libre-devops/storage-account/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  storage_accounts = {
    (local.sa_name) = {}
  }
}

# Complete call: one basic search service exercising the fuller surface. The public endpoint is
# flagged on behind an allowed_ips allow-list (the module default is public OFF; the examples turn it
# on so the behaviour is demonstrable), semantic ranking is on at the free tier, trusted Azure
# services may bypass the firewall, it carries a system-assigned identity for keyless data pulls, and
# it opens a shared private link to the storage account so it can index that data privately.
module "search_service" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  search_services = {
    (local.srch_name) = {
      sku                           = "basic"
      partition_count               = 1
      replica_count                 = 1
      semantic_search_sku           = "free"
      public_network_access_enabled = true
      network_rule_bypass_option    = "AzureServices"
      allowed_ips                   = ["203.0.113.0/24"]

      identity = { type = "SystemAssigned" }

      # Outbound private connection to the storage account (created pending the account owner's
      # approval), so the service indexes it without a public path. Swap the target for a private
      # Azure OpenAI account (subresource_name = "openai_account") for private integrated vectorization.
      shared_private_links = {
        "to-storage-blob" = {
          subresource_name   = "blob"
          target_resource_id = module.storage.ids[local.sa_name]
        }
      }
    }
  }
}
