# terraform-cloudflare-zero-trust

<!-- BEGIN LIT_QUALITY_BADGES -->

[![CI](https://github.com/lightning-it/terraform-cloudflare-zero-trust/actions/workflows/repository-quality.yml/badge.svg?branch=develop)](https://github.com/lightning-it/terraform-cloudflare-zero-trust/actions/workflows/repository-quality.yml)
[![Latest Release](https://img.shields.io/github/v/release/lightning-it/terraform-cloudflare-zero-trust?sort=semver)](https://github.com/lightning-it/terraform-cloudflare-zero-trust/releases/latest)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/lightning-it/terraform-cloudflare-zero-trust/badge)](https://scorecard.dev/viewer/?uri=github.com/lightning-it/terraform-cloudflare-zero-trust)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

<!-- END LIT_QUALITY_BADGES -->

<!-- BEGIN LIT_SHARED_RELEASE_MODEL -->

## Release and Quality Model

This repository follows the Lightning IT shared release and quality model.

See [RELEASE.md](./RELEASE.md) for:

- branch and release flow
- required quality checks
- test matrix
- release evidence
- artifact publishing
- supported repository-specific release behavior

Repository classification: **Terraform Module**.
Required test profiles: `pre-commit, terraform-fmt, terraform-validate, docs`.
Publishing targets: `terraform-registry`.

## Supported and Tested Platforms

| Platform / Product  |                  Status | Validation         |
| ------------------- | ----------------------: | ------------------ |
| ubuntu-latest       |               Supported | Terraform validate |
| terraform           | Tested where applicable | Terraform validate |
| cloudflare-provider | Tested where applicable | Terraform validate |

<!-- END LIT_SHARED_RELEASE_MODEL -->

Reusable Terraform module for Cloudflare Zero Trust Access applications and
their ordered policies.

The module is account-neutral. It contains no provider credentials, account
IDs, customer domains, identity-provider IDs, service-token IDs, import IDs,
remote-state configuration, or environment-specific workflows. A private root
configuration supplies those values and owns the Terraform state.

## Usage

```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "zero_trust" {
  source  = "lightning-it/zero-trust/cloudflare"
  version = "1.0.0"

  account_id = var.cloudflare_account_id

  access_policies = {
    deployment = {
      name     = "Example deployment automation"
      decision = "non_identity"
      include = [{
        service_token = {
          token_id = var.deployment_service_token_id
        }
      }]
    }

    workforce = {
      name     = "Example workforce access"
      decision = "allow"
      include = [{
        okta = {
          identity_provider_id = var.okta_identity_provider_id
          name                 = var.okta_group_name
        }
      }]
    }
  }

  access_applications = {
    development = {
      name             = "Example development site"
      domain           = "dev.example.com"
      policy_keys      = ["deployment", "workforce"]
      session_duration = "24h"
    }
  }
}
```

The order of `policy_keys` defines policy precedence starting at `1`.

## Ownership boundaries

The calling root module is responsible for:

- configuring the Cloudflare provider with a least-privilege API token;
- protecting the remote-state backend;
- supplying all account, domain, IdP, group, and service-token identifiers;
- declaring imports for existing Cloudflare resources;
- reviewing and approving every saved plan.

Managed policies and applications use `prevent_destroy`. Removing an item from
the input therefore fails closed until a maintainer deliberately migrates its
state and lifecycle outside this module.

## Requirements

- Terraform `>= 1.9, < 2.0`
- Cloudflare provider `>= 5.23, < 6.0`
