module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-01"
  location = local.location
  tags     = local.tags
}

module "search_service" {
  source = "../../"

  search_services = [
    {
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags

      name                          = "search-${var.short}-${var.loc}-${var.env}-01"
      sku                           = "Basic" # Example SKU
      allowed_ips                   = []
      partition_count               = 1
      public_network_access_enabled = true
      replica_count                 = 1
      semantic_search_sku           = null
      identity_type                 = "SystemAssigned" # Example for SystemAssigned identity
      identity_ids                  = []               # No identity IDs needed for SystemAssigned
    }
  ]
}
