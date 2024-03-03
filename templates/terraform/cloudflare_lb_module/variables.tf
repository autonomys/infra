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
  type    = string
  default = "subspace.network"
}

variable "network" {
  type        = string
  description = "gemini network name"
}

variable "records" {
  description = "List of DNS records."
  type = list(object({
    name     = string
    hostname = string
    value    = string
    type     = string
    tags     = list(string)
  }))
}

variable "evm_records" {
  description = "List of EVM DNS records."
  type = list(object({
    name     = string
    hostname = string
    value    = string
    type     = string
    tags     = list(string)
  }))
}

variable "monitors" {
  description = "Load balancer Monitor configuration"
  type = list(object({
    name : string
    expected_codes : string
    timeout : number
    interval : number
    retries : number
    port : number
    description : string
  }))
}

variable "load_balancers" {
  description = "Load Balancers configuration"
  type = list(object({
    name : string
    description : string
  }))
  default = [
    {
      name        = "rpc-lb"
      description = "RPC nodes load balancer"
    },
    {
      name        = "evm-lb"
      description = "EVM nodes load balancer"
    }
  ]
}
