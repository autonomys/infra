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
  default     = [3]
}

//todo change this to a map
variable "domain_labels" {
  description = "Tag of the domain to run"
  type        = list(string)
  default     = ["evm"]
}

variable "azs" {
  type        = string
  description = "Availability Zones"
  default     = "us-east-1a"
}

variable "instance_count" {
  type = map(number)
  default = {
    bootstrap = 2
    node      = 1
    farmer    = 0
  }
}

variable "additional_node_ips" {
  type = map(list(string))
  default = {
    bootstrap = [""]
    node      = [""]
    farmer    = [""]
  }
}

variable "ssh_key_name" {
  default = "hetzner"
  type    = string
}

variable "ssh_user" {
  default = "root"
  type    = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/hetzner"
}

variable "tf_token" {
  type = string
}

variable "branch_name" {
  description = "name of testing branch"
  type        = string
}
