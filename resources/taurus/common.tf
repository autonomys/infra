variable "nr_api_key" {
  description = "New relic API Key"
  type        = string
}

variable "cloudflare_email" {
  type        = string
  description = "cloudflare email address"
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
}

variable "netdata_token" {
  type      = string
  sensitive = true

}
