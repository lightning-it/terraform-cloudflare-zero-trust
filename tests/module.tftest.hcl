mock_provider "cloudflare" {}

run "plans_ordered_access_policies" {
  command = plan

  variables {
    account_id = "0123456789abcdef0123456789abcdef"

    access_policies = {
      deployment = {
        name     = "Example deployment automation"
        decision = "non_identity"
        include = [{
          service_token = {
            token_id = "00000000-0000-4000-8000-000000000001"
          }
        }]
      }

      workforce = {
        name     = "Example workforce access"
        decision = "allow"
        include = [{
          okta = {
            identity_provider_id = "00000000-0000-4000-8000-000000000002"
            name                 = "example-development-users"
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

  assert {
    condition     = cloudflare_zero_trust_access_policy.this["deployment"].decision == "non_identity"
    error_message = "The deployment policy must remain non-identity based."
  }

  assert {
    condition     = cloudflare_zero_trust_access_policy.this["workforce"].decision == "allow"
    error_message = "The workforce policy must remain identity based."
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.this["development"].domain == "dev.example.com"
    error_message = "The application domain must be passed through unchanged."
  }

  assert {
    condition     = length(cloudflare_zero_trust_access_application.this["development"].policies) == 2
    error_message = "The application must retain both ordered policies."
  }
}

