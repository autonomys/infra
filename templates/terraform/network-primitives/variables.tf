variable "nr_api_key" {
  description = "New relic API Key"
  type        = string
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

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "aws_region" {
  description = "aws region"
  type        = string
}

variable "azs" {
  type        = string
  description = "Availability Zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "aws_key_name" {
  type = string
}

variable "ssh_user" {
  type = string
}

variable "ssh_agent_identity" {
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
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    domain-prefix      = string
    reserved-only      = bool
    node-dsn-port      = number
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "auto-evm-domain-node-config" {
  description = "EVM Domain node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    domain-prefix      = string
    reserved-only      = bool
    node-dsn-port      = number
    domain-id          = number
    domain-labels      = list(string)
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "auto-id-domain-node-config" {
  description = "Auto ID Domain node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    domain-prefix      = string
    reserved-only      = bool
    node-dsn-port      = number
    domain-id          = number
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
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    reserved-only      = bool
    genesis-hash       = string
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "bootstrap-node-evm-config" {
  description = "Bootstrap node evm domain deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    reserved-only      = bool
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "bootstrap-node-autoid-config" {
  description = "Bootstrap node autoid domain deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    reserved-only      = bool
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "farmer-node-config" {
  description = "Farmer and Node configuration"
  type = object({
    instance-type          = string
    deployment-version     = number
    instance-count         = number
    docker-org             = string
    docker-tag             = string
    reserved-only          = bool
    plot-size              = string
    cache-percentage       = number
    thread-pool-size       = number
    reward-address         = string
    force-block-production = bool
    node-dsn-port          = number
    disk-volume-size       = number
    disk-volume-type       = string
    faster-sector-plotting = bool
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
