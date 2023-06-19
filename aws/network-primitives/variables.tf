variable "datadog_api_key" {
  description = "Datadog API Key"
}

variable "cloudflare_email" {
  type        = string
  description = "cloudflare email address"
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
}

variable "instance_type" {
  default = "m5a.xlarge"
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

variable "disk_volume_type" {
  type    = string
  default = "gp3"
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

variable "full-node-config" {
  description = "Full node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    regions            = list(string)
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    reserved-only      = bool
    prune              = bool
    node-dsn-port      = number
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "rpc-node-config" {
  description = "RPC node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    regions            = list(string)
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    domain-prefix      = string
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
    docker-org         = string
    docker-tag         = string
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
    docker-org         = string
    docker-tag         = string
    reserved-only      = bool
    prune              = bool
    genesis-hash       = string
    dsn-listen-port    = number
    node-dsn-port      = number
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
    docker-org             = string
    docker-tag             = string
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
