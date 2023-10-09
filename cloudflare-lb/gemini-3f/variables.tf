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
  type = string
}

variable "network" {
  type        = string
  description = "gemini network name"
}

variable "rpc_prefix" {
  type    = string
  default = "rpc"

}

variable "domain_prefix" {
  type    = string
  default = "domain"

}
