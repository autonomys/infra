variable "network_name" {
  description = "Network name"
  type        = string
  default     = "devnet"

}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "farmer_reward_address" {
  description = "Farmer's reward address"
  type        = string
}

//todo change this to a map
variable "domain_labels" {
  description = "Tag of the domain to run"
  type        = list(string)
  default     = ["auto-evm"]
}

variable "instance_type" {
  type = map(string)
  default = {
    bootstrap        = "m6a.xlarge"
    rpc              = "m6a.xlarge"
    auto-evm         = "m6a.xlarge"
    auto-id          = "m6a.xlarge"
    rpc-indexer      = "m6a.xlarge"
    auto-evm-indexer = "m6a.xlarge"
    farmer           = "c6id.2xlarge"
    evm_bootstrap    = "m6a.xlarge"
    autoid_bootstrap = "m6a.xlarge"
  }
}

variable "vpc_id" {
  default = "devnet-vpc"
  type    = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "instance_count" {
  type = map(number)
  default = {
    bootstrap        = 2
    rpc              = 1
    auto-evm         = 1
    auto-id          = 0
    rpc-indexer      = 0
    auto-evm-indexer = 0
    farmer           = 1
    evm_bootstrap    = 1
    autoid_bootstrap = 0
  }
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
}

variable "azs" {
  type        = string
  description = "Availability Zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.35.1.0/24"]
}

variable "disk_volume_size" {
  type = number
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "aws_key_name" {
  type = string
}

variable "ssh_user" {
  default = "ubuntu"
  type    = string
}

variable "ssh_agent_identity" {
  type = string
}

variable "cache_percentage" {
  description = "cache percentage"
  type        = number
  default     = 50
}

variable "thread_pool_size" {
  description = "thread pool size (number of cpu cores)"
  type        = number
  default     = 8
}

variable "nr_api_key" {
  description = "New relic API Key"
  type        = string
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
}
