variable "network-name" {
  description = "Network name"
  type        = string
}

variable "deployment-color" {
  description = "Deployment color environment"
  type        = string
}

variable "path-to-scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "path-to-configs" {
  description = "Path to the configs"
  type        = string
}

variable "archive-node-config" {
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
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "squid-node-config" {
  description = "Block squid backend configuration"
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
    disk-volume-size   = number
    disk-volume-type   = string
  })

}
