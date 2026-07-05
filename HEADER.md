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
- **Shared private links** per service: the service's *own* outbound private connections to data
  sources. This is how private RAG actually works: the service reaches a **private** Storage account
  to index it, or a **private** Azure OpenAI / cognitive account for integrated vectorization
  (embeddings), or Key Vault / Cosmos / SQL, without any of them being public. Each link is created
  pending the target owner's approval.

Scale with `partition_count` / `replica_count` (a `check` warns when a production-tier SKU has no
query SLA), enable semantic ranking with `semantic_search_sku`, and let trusted Azure services in with
`network_rule_bypass_option = "AzureServices"`. The resource group is passed by id and parsed.

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
  ranking, a system-assigned identity, the public endpoint flagged on behind an `allowed_ips`
  allow-list with trusted-service bypass, and a shared private link to a Storage account so the
  service can index that data privately.

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
