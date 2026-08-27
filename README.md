# terraform-cloudflare-zero-trust

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
