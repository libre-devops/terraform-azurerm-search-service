<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure AI Search

Azure AI Search (Cognitive Search) services keyed by name, secure by default: Entra-only auth, no
public endpoint, and a managed identity for keyless data pulls.

[![CI](https://github.com/libre-devops/terraform-azurerm-search-service/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-search-service/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-search-service?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-search-service/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-search-service)](./LICENSE)

---

## Overview

Azure AI Search (formerly Cognitive Search) services keyed by name, secure by default. Secure
defaults, all caller-overridable:

- **Entra-only auth**: `local_authentication_enabled = false`, so the admin and query API keys are
  off and access goes through Entra ID / RBAC data-plane roles.
- **No public endpoint**: `public_network_access_enabled = false`. Pair with a private endpoint (the
  `private-endpoint` module), or set it `true` with an `allowed_ips` allow-list.
- **System-assigned identity**, so the service can pull from data sources (a Storage account, a
  Cognitive Services account) with its managed identity rather than a key. This is the retrieval side
  of a RAG pattern that pairs with the `cognitive-account` module.

Scale with `partition_count` / `replica_count`, enable semantic ranking with `semantic_search_sku`,
and let trusted Azure services in with `network_rule_bypass_option = "AzureServices"`. The resource
group is passed by id and parsed.

## Usage

```hcl
module "search_service" {
  source  = "libre-devops/search-service/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  search_services = {
    "srch-ldo-uks-prd-001" = {
      sku                 = "standard"
      semantic_search_sku = "free"
    }
  }
}
```

Because API keys are disabled, callers authenticate with Entra ID and need the appropriate data-plane
role (for example `Search Index Data Reader` or `Search Service Contributor`), granted with the
`role-assignment` module.

## Examples

- [`examples/minimal`](./examples/minimal) - a single basic service with the secure defaults.
- [`examples/complete`](./examples/complete) - a service exercising the fuller surface: semantic
  ranking, a scaled partition/replica count, a system-assigned identity, and the public endpoint
  flagged on behind an `allowed_ips` allow-list with trusted-service bypass.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_search_service.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/search_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for the search services. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource id of the resource group to create the search services in. The name and subscription are parsed from it (pass the rg module's ids output). | `string` | n/a | yes |
| <a name="input_search_services"></a> [search\_services](#input\_search\_services) | Azure AI Search services to create, keyed by service name. Secure defaults, all overridable:<br/>  - local\_authentication\_enabled = false   (Entra ID / RBAC only, admin and query API keys off)<br/>  - public\_network\_access\_enabled = false   (no public endpoint; pair with a private endpoint, or<br/>                                            set true with an allowed\_ips allow-list)<br/>  - identity.type = SystemAssigned          (so the service can pull from data sources, such as a<br/>                                            Storage account or a Cognitive Services account, using<br/>                                            its managed identity rather than a key)<br/><br/>Per-service fields:<br/>  sku                                       basic, standard, standard2, standard3,<br/>                                            storage\_optimized\_l1/l2, or free.<br/>  partition\_count / replica\_count           Scale out storage and query throughput.<br/>  hosting\_mode                              default, or highDensity (standard3 only).<br/>  semantic\_search\_sku                       free or standard to enable semantic ranking.<br/>  network\_rule\_bypass\_option                None (default) or AzureServices to let trusted Azure<br/>                                            services reach the service.<br/>  allowed\_ips                               Inbound IPv4 addresses / CIDRs allowed when public<br/>                                            access is enabled.<br/>  authentication\_failure\_mode               http401WithBearerChallenge or http403 (only meaningful<br/>                                            when local authentication is enabled).<br/>  customer\_managed\_key\_enforcement\_enabled  Require all indexes / synonym maps to use a CMK.<br/>  identity                                  Managed identity (SystemAssigned by default). | <pre>map(object({<br/>    sku                                      = optional(string, "basic")<br/>    local_authentication_enabled             = optional(bool, false)<br/>    authentication_failure_mode              = optional(string)<br/>    public_network_access_enabled            = optional(bool, false)<br/>    allowed_ips                              = optional(list(string), [])<br/>    network_rule_bypass_option               = optional(string)<br/>    partition_count                          = optional(number, 1)<br/>    replica_count                            = optional(number, 1)<br/>    hosting_mode                             = optional(string, "default")<br/>    semantic_search_sku                      = optional(string)<br/>    customer_managed_key_enforcement_enabled = optional(bool)<br/><br/>    identity = optional(object({<br/>      type         = optional(string, "SystemAssigned")<br/>      identity_ids = optional(list(string))<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the search services. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Map of service name to its search endpoint URL. |
| <a name="output_identities"></a> [identities](#output\_identities) | Map of service name to its managed identity { principal\_id, tenant\_id } (principal\_id is populated for system-assigned identities). |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of service name to its resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of service name to a { name, id } object, for passing where both are needed together. |
| <a name="output_names"></a> [names](#output\_names) | The service names. |
| <a name="output_primary_keys"></a> [primary\_keys](#output\_primary\_keys) | Map of service name to its primary admin key (empty when local\_authentication\_enabled is false). |
| <a name="output_query_keys"></a> [query\_keys](#output\_query\_keys) | Map of service name to its query keys (list of { name, key }; empty when local\_authentication\_enabled is false). |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name parsed from resource\_group\_id. |
| <a name="output_secondary_keys"></a> [secondary\_keys](#output\_secondary\_keys) | Map of service name to its secondary admin key (empty when local\_authentication\_enabled is false). |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription id parsed from resource\_group\_id. |
| <a name="output_tags"></a> [tags](#output\_tags) | The tags applied to the services. |
<!-- END_TF_DOCS -->
