resource "cloudflare_zero_trust_access_policy" "this" {
  for_each = var.access_policies

  account_id = var.account_id
  name       = each.value.name
  decision   = each.value.decision
  include    = each.value.include

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zero_trust_access_application" "this" {
  for_each = var.access_applications

  account_id       = var.account_id
  name             = each.value.name
  domain           = each.value.domain
  type             = each.value.type
  session_duration = each.value.session_duration

  policies = [
    for index, policy_key in each.value.policy_keys : {
      id         = cloudflare_zero_trust_access_policy.this[policy_key].id
      precedence = index + 1
    }
  ]

  lifecycle {
    prevent_destroy = true

    precondition {
      condition = alltrue([
        for policy_key in each.value.policy_keys :
        contains(keys(var.access_policies), policy_key)
      ])
      error_message = "Every application policy key must exist in access_policies."
    }
  }
}

