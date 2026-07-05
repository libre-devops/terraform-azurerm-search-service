locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  srch_name = "srch-${var.short}-${var.loc}-${terraform.workspace}-002"
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

# Complete call: one basic search service exercising the fuller surface. The public endpoint is
# flagged on behind an allowed_ips allow-list (the module default is public OFF; the examples turn it
# on so the behaviour is demonstrable), semantic ranking is on at the free tier, trusted Azure
# services may bypass the firewall, and it carries a system-assigned identity for keyless data pulls.
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
    }
  }
}
