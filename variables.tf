variable "account_id" {
  type        = string
  description = "Cloudflare account that owns the managed Zero Trust resources."

  validation {
    condition     = can(regex("^[0-9A-Fa-f]{32}$", var.account_id))
    error_message = "account_id must be a 32-character hexadecimal Cloudflare account ID."
  }
}

variable "access_policies" {
  description = "Cloudflare Access policies keyed by a stable caller-defined identifier."
  type = map(object({
    name     = string
    decision = string
    include = list(object({
      okta = optional(object({
        identity_provider_id = string
        name                 = string
      }))
      service_token = optional(object({
        token_id = string
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for policy in values(var.access_policies) : [
        for selector in policy.include :
        (selector.okta != null ? 1 : 0) +
        (selector.service_token != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "Every include selector must configure exactly one supported selector type."
  }

  validation {
    condition = alltrue([
      for policy in values(var.access_policies) :
      contains(["allow", "deny", "bypass", "non_identity"], policy.decision)
    ])
    error_message = "Policy decision must be allow, deny, bypass, or non_identity."
  }

  validation {
    condition = alltrue([
      for policy in values(var.access_policies) : length(policy.include) > 0
    ])
    error_message = "Every access policy must contain at least one include selector."
  }
}

variable "access_applications" {
  description = "Cloudflare Access applications keyed by a stable caller-defined identifier."
  type = map(object({
    name                      = string
    domain                    = string
    type                      = optional(string, "self_hosted")
    session_duration          = optional(string, "24h")
    policy_keys               = list(string)
    public_destinations       = optional(list(string))
    allowed_idps              = optional(set(string))
    auto_redirect_to_identity = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for application in values(var.access_applications) :
      application.public_destinations == null ? true : (
        length(application.public_destinations) > 0 &&
        length(application.public_destinations) == length(distinct(application.public_destinations)) &&
        contains(application.public_destinations, application.domain)
      )
    ])
    error_message = "Explicit public destinations must be non-empty, unique, and include the primary domain."
  }

  validation {
    condition = alltrue([
      for application in values(var.access_applications) :
      application.auto_redirect_to_identity == true ? (
        application.allowed_idps == null ? false : length(application.allowed_idps) == 1
      ) : true
    ])
    error_message = "Automatic identity redirect requires exactly one explicit allowed identity provider."
  }

  validation {
    condition = alltrue([
      for application in values(var.access_applications) :
      length(application.policy_keys) == length(distinct(application.policy_keys)) &&
      length(application.policy_keys) > 0
    ])
    error_message = "Every application must reference a non-empty, duplicate-free policy_keys list."
  }
}
