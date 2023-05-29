variable "farmer_reward_address" {
  description = "Farmer's reward address"
  type        = string
}

variable "domain_id" {
  description = "Domain ID"
  type        = list(number)
  default     = [1, 2, 3]
}

variable "domain_labels" {
  description = "Tag of the domain to run"
  type        = list(string)
  default     = ["evm", "payments"]
}


variable "bootstrap_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = [""]
}

variable "full_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = [""]
}

variable "rpc_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = [""]
}

variable "domain_node_ips" {
  description = "IP of domain node"
  type        = list(string)
  default     = [""]
}

variable "farmer_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = [""]
}

variable "instance_type" {
  default = "t3.small"
  type    = string
}

variable "vpc_id" {
  default = "default"
  type    = string
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-1"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.1.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["172.31.2.0/24"]
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

