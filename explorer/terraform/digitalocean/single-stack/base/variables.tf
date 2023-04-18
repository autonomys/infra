variable "network-name" {
  description = "Network name"
  type        = string
}

variable "path-to-scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "archive-squid-node-config" {
  description = "Squid Archive configuration"
  type = object({
    deployment-color   = string
    network-name       = string
    domain-prefix      = string
    droplet_size       = string
    deployment-version = number
    regions            = list(string)
    nodes-per-region   = number
    docker-org         = string
    docker-tag         = string
    prune              = bool
    environment        = string
    #  disk_volume_size            = string
  })
}

variable "explorer-node-config" {
  description = "Block explorer backend configuration"
  type = object({
    deployment-color   = string
    network-name       = string
    domain-prefix      = string
    droplet_size       = string
    deployment-version = number
    regions            = list(string)
    nodes-per-region   = number
    docker-org         = string
    docker-tag         = string
    prune              = bool
    environment        = string
    #  disk_volume_size            = string
  })

}

