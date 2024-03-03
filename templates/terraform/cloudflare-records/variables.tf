variable "cloudflare_secrets" {
  description = "Cloudflare secrets"
  type = object({
    api_token  = string
    account_id = string
  })
  sensitive = true
}

variable "cloudflare_records" {
  description = "Cloudflare Records struct"
  type = list(object({
    zone_id = optional(string, "")
    name    = optional(string, "")
    value   = optional(string, "")
    ttl     = optional(number, 1)
    type    = optional(string, "A")
    proxied = optional(bool, true)
    comment = optional(string, "")
    tags    = optional(set(string), [])
  }))

  default = []
}
