variable "network_name" {
  description = "Network name"
  type        = string
  default     = "mainnet"

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
variable "domain_id" {
  description = "Domain ID"
  type        = list(number)
  default     = [0, 1]
}

//todo change this to a map
variable "domain_labels" {
  description = "Tag of the domain to run"
  type        = list(string)
  default     = ["auto-evm", "autoid"]
}

variable "instance_type" {
  type = map(string)
  default = {
    bootstrap        = "c7a.2xlarge"
    rpc              = "m7a.2xlarge"
    domain           = "m7a.2xlarge"
    rpc-indexer      = "c7a.4xlarge"
    auto-evm-indexer = "c7a.4xlarge"
    farmer           = "c7a.2xlarge"
    evm_bootstrap    = "c7a.xlarge"
    autoid_bootstrap = "c7a.xlarge"
  }
}

variable "vpc_id" {
  default = "mainnet-vpc"
  type    = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "instance_count" {
  type = map(number)
  default = {
    bootstrap        = 0
    rpc              = 2
    domain           = 4
    autoid           = 0
    rpc-indexer      = 0
    auto-evm-indexer = 0
    farmer           = 0
    evm_bootstrap    = 1
    autoid_bootstrap = 0
  }
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-2"]
}

variable "azs" {
  type        = string
  description = "Availability Zones"
  default     = "us-east-2a"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.38.1.0/24"]
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
  default = "deployer"
  type    = string
}

variable "ssh_user" {
  default = "ubuntu"
  type    = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/deployer.pem"
}

variable "pot_external_entropy" {
  description = "External entropy, used initially when PoT chain starts to derive the first seed"
  type        = string
  default     = "test"
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
