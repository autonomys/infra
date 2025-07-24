variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "new_relic_api_key" {
  description = "New relic API Key"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare api token"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "AWS VPC name"
  type        = string
}

variable "vpc_cidr_block" {
  description = "AWS VPC's CIDR"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "availability_zone" {
  description = "AWS availability Zone"
  type        = string
}

// TODO: update this to single subnet cidr
variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR values"
  type        = list(string)
}

variable "aws_ssh_key_name" {
  description = "AWS deployer's SSH key"
  type        = string
}

variable "ssh_user" {
  description = "Instance ssh user. Usually `ubuntu` for Ubuntu based machines"
  type        = string
}

variable "ssh_agent_identity" {
  description = "AWS SSH key's public key that is loaded into SSH-Agent"
  type        = string
}

variable "network_name" {
  description = "Network name which is also the Chain's name"
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

variable "farmer-node-config" {
  description = "Farmer and Node configuration. Requires an NVME instance storage and not EBS"
  type = object({
    instance-type          = string
    deployment-version     = number
    instance-count         = number
    docker-org             = string
    docker-tag             = string
    reserved-only          = bool
    plot-size              = string
    cache-percentage       = number
    reward-address         = string
    force-block-production = bool
    faster-sector-plotting = bool
  })
}

variable "rpc-node-config" {
  description = "RPC node deployment config"
  type = object({
    instance-type      = string
    deployment-version = number
    instance-count     = number
    docker-org         = string
    docker-tag         = string
    dns-prefix         = string
    reserved-only      = bool
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
    domain-id          = number
    domain-prefix      = string
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
    reserved-only      = bool
    domain-id          = number
    operator-id        = number
    domain-prefix      = string
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
    domain-id          = number
    domain-prefix      = string
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
    reserved-only      = bool
    domain-id          = number
    operator-id        = number
    domain-prefix      = string
    disk-volume-size   = number
    disk-volume-type   = string
  })
}
