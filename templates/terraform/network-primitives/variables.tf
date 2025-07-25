variable "nr_api_key" {
  description = "New relic API Key"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  type        = string
  description = "cloudflare email address"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "cloudflare zone id"
  sensitive   = true
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
  sensitive   = true
}

variable "instance_type" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "instance_count" {
  type = map(number)
  default = {
    bootstrap        = 2
    rpc              = 2
    rpc-indexer      = 0
    auto-evm-indexer = 0
    farmer           = 1
    evm_bootstrap    = 0
    autoid_bootsrap  = 0
  }
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
}

variable "azs" {
  type        = string
  description = "Availability Zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
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
  type = string
}

variable "network_name" {
  description = "Network name"
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

variable "rpc-indexer-node-config" {
  description = "RPC indexer node deployment config"
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
    domain-prefix      = list(string)
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

variable "auto-evm-indexer-node-config" {
  description = "Auto EVM indexer node deployment config"
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

variable "bootstrap-node-autoid-config" {
  description = "Bootstrap node autoid domain deployment config"
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
    docker-org             = string
    docker-tag             = string
    reserved-only          = bool
    prune                  = bool
    plot-size              = string
    cache-percentage       = number
    thread-pool-size       = number
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

variable "pot_external_entropy" {
  description = "External entropy, used initially when PoT chain starts to derive the first seed"
  type        = string
}
