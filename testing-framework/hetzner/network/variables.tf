variable "farmer_reward_address" {
  description = "Farmer's reward address"
  type        = string
}

variable "network_name" {
  description = "Network name"
  type        = string
}

//todo change this to a map
variable "domain_id" {
  description = "Domain ID"
  type        = list(number)
  default     = [0]
}

//todo change this to a map
variable "domain_labels" {
  description = "Tag of the domain to run"
  type        = list(string)
  default     = ["evm"]
}

variable "instance_count" {
  type = map(number)
  default = {
    bootstrap     = 1
    node          = 1
    farmer        = 1
    domain        = 1
    evm_bootstrap = 1
  }
}

variable "additional_node_ips" {
  type = map(list(string))
  default = {
    bootstrap     = [""]
    node          = [""]
    farmer        = [""]
    domain        = [""]
    evm_bootstrap = [""]
  }
}

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/hetzner"
}

variable "tf_token" {
  type      = string
  sensitive = true
}

variable "branch_name" {
  description = "name of testing branch"
  type        = string
}

variable "genesis_hash" {
  description = "Genesis hash"
  type        = string
}

variable "cache_percentage" {
  description = "cache percentage"
  type        = string
  default     = "50"
}

variable "thread_pool_size" {
  description = "thread pool size (number of cpu cores)"
  type        = string
  default     = "8"
}
