variable "instance_type" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "azs" {
  type        = string
  description = "Availability Zones"
  default     = "us-west-2a"
}

variable "instance_count" {
  type = map(number)
  default = {
    bootstrap = 2
    node      = 1
    domain    = 0
    farmer    = 1
  }
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-west-2"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}

variable "network_name" {
  description = "Network name"
  type        = string
}

variable "path_to_scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "piece_cache_size" {
  description = "Piece cache size"
  type        = string
  default     = "1GiB"
}

variable "node-config" {
  description = "Full node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    regions            = list(string)
    instance-count     = number
    repo-org           = string
    node-tag           = string
    reserved-only      = bool
    prune              = bool
    node-dsn-port      = number
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "domain-node-config" {
  description = "Domain node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    regions            = list(string)
    instance-count     = number
    repo-org           = string
    node-tag           = string
    domain-prefix      = string
    reserved-only      = bool
    prune              = bool
    node-dsn-port      = number
    enable-domains     = bool
    domain-id          = list(number)
    domain-labels      = list(string)
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "bootstrap-node-config" {
  description = "Bootstrap node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    regions            = list(string)
    instance-count     = number
    repo-org           = string
    node-tag           = string
    reserved-only      = bool
    prune              = bool
    genesis-hash       = string
    dsn-listen-port    = number
    node-dsn-port      = number
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "bootstrap-node-evm-config" {
  description = "Bootstrap node evm domain deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    regions            = list(string)
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    reserved-only      = bool
    prune              = bool
    genesis-hash       = string
    dsn-listen-port    = number
    node-dsn-port      = number
    operator-port      = number
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "farmer-node-config" {
  description = "Farmer and Node configuration"
  type = object({
    instance-type          = string
    deployment-version     = number
    regions                = list(string)
    instance-count         = number
    repo-org               = string
    node-tag               = string
    reserved-only          = bool
    prune                  = bool
    plot-size              = string
    reward-address         = string
    force-block-production = bool
    node-dsn-port          = number
    disk-volume-size       = number
    disk-volume-type       = string
  })
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

variable "private_key_path" {
  type = string
}

variable "tf_token" {
  type      = string
  sensitive = true
}

variable "ssh_user" {
  default = "ubuntu"
  type    = string
}

variable "branch_name" {
  description = "name of testing branch"
  type        = string
}

variable "genesis_hash" {
  description = "Genesis hash"
  type        = string

}
