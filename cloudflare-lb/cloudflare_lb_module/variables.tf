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
  default = [
    {
      name     = "rpc-0"
      hostname = "rpc.gemini-3f.subspace.network"
      value    = "52.91.27.239"
      type     = "A"
      tags     = ["rpc", "us"]
    },
    {
      name     = "rpc-1"
      hostname = "rpc.gemini-3f.subspace.network"
      value    = "65.108.232.52"
      type     = "A"
      tags     = ["rpc", "eu"]
    },
  ]
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
  default = [
    {
      name     = "evm-0"
      hostname = "domain-3.gemini-3f.subspace.network"
      value    = "174.129.202.104"
      type     = "A"
      tags     = ["domain", "evm", "us"]
    },
    {
      name     = "evm-1"
      hostname = "domain-3.gemini-3f.subspace.network"
      value    = "65.108.228.84"
      type     = "A"
      tags     = ["domain", "evm", "eu"]
    },
  ]
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
  default = [
    {
      name           = "check-rpc-tcp"
      expected_codes = "2xx"
      timeout        = 5
      interval       = 60
      retries        = 2
      port           = 30333
      description    = "TCP Check port- expect 2xx"
    },
    {
      name           = "check-evm-tcp"
      expected_codes = "2xx"
      timeout        = 5
      interval       = 60
      retries        = 2
      port           = 30303
      description    = "EVM Check port- expect 2xx"
    }
  ]
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
