variable "netdata_token" {
  type      = string
  sensitive = true

}

variable "node_tag" {
  type = string
}

variable "nr_api_key" {
  description = "New relic API Key"
  type        = string
}

variable "cloudflare_email" {
  type        = string
  description = "cloudflare email address"
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
}

variable "network_name" {
  description = "Network name"
  type        = string
  default     = "gemini-3h"
}

variable "instance_type" {
  type = string
}

variable "vpc_id" {
  default = "explorer-gemini-3h-vpc"
  type    = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-2b"]
}

variable "instance_count_blue" {
  type = number
}

variable "instance_count_green" {
  type = number
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-2"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
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
  default = "explorer-deployer"
  type    = string
}

variable "ssh_user" {
  default = "ubuntu"
  type    = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/explorer-deployer.pem"
}

variable "disk_volume_size" {
  type    = number
  default = 200
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}

variable "postgres_password" {
  sensitive = true
  type      = string
}

variable "prometheus_secret" {
  sensitive = true
  type      = string
}
