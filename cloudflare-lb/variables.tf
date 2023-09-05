variable "account_id" {
  type        = string
  description = "Cloudflare account id"
  sensitive   = true
}

variable "zone_id" {
  type        = string
  description = "Cloudflare zone id"
  sensitive   = true

}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
  sensitive   = true
}

variable "domain" {
  default = "subspace.network"
}

variable "network" {
  type        = string
  description = "gemini network name"
}
