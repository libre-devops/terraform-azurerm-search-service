# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no
# features block, and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  location          = "uksouth"
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01"

  search_services = {
    "srch-ldo-uks-tst-01" = {}
  }
}

# The defaults are secure: Entra-only auth, no public endpoint, a system-assigned identity, on the
# basic SKU with a single partition and replica.
run "creates_secure_service" {
  command = plan

  assert {
    condition     = azurerm_search_service.this["srch-ldo-uks-tst-01"].sku == "basic"
    error_message = "The default SKU should be basic."
  }

  assert {
    condition     = azurerm_search_service.this["srch-ldo-uks-tst-01"].local_authentication_enabled == false
    error_message = "Services must be Entra-only (API keys disabled) by default."
  }

  assert {
    condition     = azurerm_search_service.this["srch-ldo-uks-tst-01"].public_network_access_enabled == false
    error_message = "The public endpoint must be disabled by default."
  }

  assert {
    condition     = azurerm_search_service.this["srch-ldo-uks-tst-01"].identity[0].type == "SystemAssigned"
    error_message = "The service should get a system-assigned identity by default."
  }

  assert {
    condition     = length(azurerm_search_service.this) == 1
    error_message = "One search service should be created per map entry."
  }
}

# Validation: an unsupported SKU is rejected.
run "rejects_invalid_sku" {
  command = plan

  variables {
    search_services = {
      "srch-ldo-uks-tst-01" = { sku = "ultra" }
    }
  }

  expect_failures = [var.search_services]
}

# Validation: highDensity hosting is only valid on standard3.
run "rejects_high_density_on_basic" {
  command = plan

  variables {
    search_services = {
      "srch-ldo-uks-tst-01" = { sku = "basic", hosting_mode = "highDensity" }
    }
  }

  expect_failures = [var.search_services]
}

# Validation: an invalid semantic search SKU is rejected.
run "rejects_invalid_semantic_sku" {
  command = plan

  variables {
    search_services = {
      "srch-ldo-uks-tst-01" = { semantic_search_sku = "premium" }
    }
  }

  expect_failures = [var.search_services]
}

# Shared private links are flattened to "<service>/<link>" and created against the service.
run "creates_shared_private_link" {
  command = plan

  variables {
    search_services = {
      "srch-ldo-uks-tst-01" = {
        shared_private_links = {
          "to-storage" = {
            subresource_name   = "blob"
            target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Storage/storageAccounts/saldouksts01"
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_search_shared_private_link_service.this["srch-ldo-uks-tst-01/to-storage"].subresource_name == "blob"
    error_message = "The shared private link should target the blob subresource and be keyed as <service>/<link>."
  }

  assert {
    condition     = length(azurerm_search_shared_private_link_service.this) == 1
    error_message = "One shared private link should be created per nested map entry."
  }
}
