variable "netdata_token" {
  default   = ""
  type      = string
  sensitive = true

}

variable "instance_type" {
  default = "m6a.2xlarge"
  type    = string
}

variable "vpc_id" {
  default = "default"
  type    = string
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-2c"]
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "instance_count_blue" {
  type    = number
  default = 1
}

variable "instance_count_green" {
  type    = number
  default = 0
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-2"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.3.0/24"]
}

variable "disk_volume_size" {
  type    = number
  default = 800
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}


variable "ssh_user" {
  default = "ubuntu"
  type    = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/explorer-deployer.pem"
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

variable "network_name" {
  description = "Network name"
  type        = string
  default     = "gemini-3d"
}

variable "deployment_color" {
  description = "Deployment environment"
  type        = string
}

variable "path_to_scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "path_to_configs" {
  description = "Path to the configs"
  type        = string
}

variable "blue-squid-node-config" {
  description = "squid blue configuration"
  type = object({
    deployment-color     = string
    network-name         = string
    domain-prefix        = string
    instance-type        = string
    deployment-version   = number
    regions              = list(string)
    instance-count-blue  = number
    prune                = bool
    disk-volume-size     = number
    disk-volume-type     = string
    environment          = string
  })
}

variable "green-squid-node-config" {
  description = "squid blue configuration"
  type = object({
    deployment-color     = string
    network-name         = string
    domain-prefix        = string
    instance-type        = string
    deployment-version   = number
    regions              = list(string)
    instance-count-green = number
    prune                = bool
    disk-volume-size     = number
    disk-volume-type     = string
    environment          = string
  })
}

variable "archive-node-config" {
  description = "archive squid configuration"
  type = object({
    network-name         = string
    domain-prefix        = string
    instance-type        = string
    deployment-version   = number
    regions              = list(string)
    instance-count  = number
    prune                = bool
    disk-volume-size     = number
    disk-volume-type     = string
  })
}