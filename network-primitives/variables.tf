variable "network-name" {
  description = "Network name"
  type        = string
}

variable "path-to-scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API Key"
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
    droplet_size        = string
    deployment-version  = number
    regions             = list(string)
    nodes-per-region    = number
    additional-node-ips = list(string)
    docker-org          = string
    docker-tag          = string
    reserved-only       = bool
    prune               = bool
    node-dsn-port       = number
    domain-id           = number
  })
}

variable "rpc-node-config" {
  description = "RPC node deployment config"
  type = object({
    droplet_size        = string
    deployment-version  = number
    regions             = list(string)
    nodes-per-region    = number
    additional-node-ips = list(string)
    docker-org          = string
    docker-tag          = string
    domain-prefix       = string
    reserved-only       = bool
    prune               = bool
    node-dsn-port       = number
    enable-domains      = bool
    domain-id           = number
  })
}

variable "bootstrap-node-config" {
  description = "Bootstrap node deployment config"
  type = object({
    droplet_size        = string
    deployment-version  = number
    regions             = list(string)
    nodes-per-region    = number
    additional-node-ips = list(string)
    docker-org          = string
    docker-tag          = string
    reserved-only       = bool
    prune               = bool
    genesis-hash        = string
    dsn-listen-port     = number
    node-dsn-port       = number
    domain-id           = number
  })
}

variable "farmer-node-config" {
  description = "Farmer and Node configuration"
  type = object({
    droplet_size           = string
    deployment-version     = number
    regions                = list(string)
    nodes-per-region       = number
    additional-node-ips    = list(string)
    docker-org             = string
    docker-tag             = string
    reserved-only          = bool
    prune                  = bool
    plot-size              = string
    reward-address         = string
    force-block-production = bool
    node-dsn-port          = number
    domain-id              = number
  })
}
