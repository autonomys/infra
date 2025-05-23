variable "instance_type" {
  default = "m7a.2xlarge"
  type    = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
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

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-2b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "disk_volume_size" {
  type    = number
  default = 400
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
  default     = "taurus"
}

variable "path_to_scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "path_to_configs" {
  description = "Path to the configs"
  type        = string
}

variable "blue-subql-node-config" {
  description = "subql blue configuration"
  type = object({
    deployment-color    = string
    network-name        = string
    domain-prefix       = string
    docker-tag          = string
    instance-type       = string
    deployment-version  = number
    regions             = list(string)
    instance-count-blue = number
    disk-volume-size    = number
    disk-volume-type    = string
    environment         = string
  })
}

variable "green-subql-node-config" {
  description = "subql blue configuration"
  type = object({
    deployment-color     = string
    network-name         = string
    domain-prefix        = string
    docker-tag           = string
    instance-type        = string
    deployment-version   = number
    regions              = list(string)
    instance-count-green = number
    disk-volume-size     = number
    disk-volume-type     = string
    environment          = string
  })
}

variable "nova-blue-subql-node-config" {
  description = "subql blue configuration"
  type = object({
    deployment-color    = string
    network-name        = string
    domain-prefix       = string
    docker-tag          = string
    instance-type       = string
    deployment-version  = number
    regions             = list(string)
    instance-count-blue = number
    disk-volume-size    = number
    disk-volume-type    = string
    environment         = string
  })
}

variable "nova-green-subql-node-config" {
  description = "subql blue configuration"
  type = object({
    deployment-color     = string
    network-name         = string
    domain-prefix        = string
    docker-tag           = string
    instance-type        = string
    deployment-version   = number
    regions              = list(string)
    instance-count-green = number
    disk-volume-size     = number
    disk-volume-type     = string
    environment          = string
  })
}

variable "postgres_password" {
  sensitive = true
  type      = string
}

variable "hasura_graphql_admin_secret" {
  sensitive = true
  type      = string
}

variable "hasura_graphql_jwt_secret" {
  sensitive = true
  type      = string
}
