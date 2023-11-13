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

variable "instance_count" {
  type = map(number)
  default = {
    bootstrap = 2
    node      = 1
    farmer    = 1
    domain    = 1
  }
}

variable "additional_node_ips" {
  type = map(list(string))
  default = {
    bootstrap = [""]
    node      = [""]
    farmer    = [""]
    domain    = [""]
  }
}

variable "ssh_key_name" {
  type    = string
  default = "hetzner"
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
