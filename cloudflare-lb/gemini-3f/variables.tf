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

variable "rpc_ips" {
  type    = list(string)
  default = ["52.91.27.239", "65.108.232.52"]
}

variable "evm_domain_ips" {
  type    = list(string)
  default = ["174.129.202.104", "65.108.228.84"]
}
