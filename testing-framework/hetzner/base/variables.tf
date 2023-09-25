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
    deployment-version  = number
    instance-count      = number
    docker-org          = string
    docker-tag          = string
    additional-node-ips = list(string)
    reserved-only       = bool
    prune               = bool
    node-dsn-port       = number
  })
}

variable "domain-node-config" {
  description = "Domain node deployment config"
  type = object({
    deployment-version  = number
    instance-count      = number
    docker-org          = string
    docker-tag          = string
    additional-node-ips = list(string)
    domain-prefix       = string
    reserved-only       = bool
    prune               = bool
    node-dsn-port       = number
    enable-domains      = bool
    domain-id           = list(number)
    domain-labels       = list(string)
  })
}

variable "bootstrap-node-config" {
  description = "Bootstrap node deployment config"
  type = object({
    deployment-version  = number
    instance-count      = number
    docker-org          = string
    docker-tag          = string
    additional-node-ips = list(string)
    reserved-only       = bool
    prune               = bool
    genesis-hash        = string
    dsn-listen-port     = number
    node-dsn-port       = number
  })
}

variable "farmer-node-config" {
  description = "Farmer and Node configuration"
  type = object({
    deployment-version     = number
    instance-count         = number
    docker-org             = string
    docker-tag             = string
    additional-node-ips    = list(string)
    reserved-only          = bool
    prune                  = bool
    plot-size              = string
    reward-address         = string
    force-block-production = bool
    node-dsn-port          = number
  })
}

variable "ssh_key_name" {
  default = "hetzner"
  type    = string
}

variable "ssh_user" {
  default = "root"
  type    = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/hetzner"
}

variable "branch_name" {
  description = "name of testing branch"
  type        = string
}
