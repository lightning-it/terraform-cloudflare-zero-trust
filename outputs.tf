output "access_application_ids" {
  description = "Cloudflare Access application IDs keyed by caller-defined application key."
  value = {
    for key, application in cloudflare_zero_trust_access_application.this :
    key => application.id
  }
}

output "access_policy_ids" {
  description = "Cloudflare Access policy IDs keyed by caller-defined policy key."
  value = {
    for key, policy in cloudflare_zero_trust_access_policy.this :
    key => policy.id
  }
}

