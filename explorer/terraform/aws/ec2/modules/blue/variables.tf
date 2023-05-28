variable "do_token" {
  description = "Digital ocean API key"
}

variable "ssh_identity" {
  description = "SSH agent identity to use to connect to remote host"
}

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

variable "network_name" {
  description = "Network name"
  type        = string
}

variable "droplet_size" {
  description = "Droplet size"
  type        = string
  default     = "s-6vcpu-16gb"
}

variable "deployment_color" {
  description = "Deployment environment"
  type        = string
  default     = "blue"
}

variable "disk_volume_size" {
  description = "Disk Volume Size"
  type        = number
  default     = 400
}

variable "disk_volume_type" {
  description = "Disk Volume Filesystem Type"
  type        = string
  default     = "ext4"
}

variable "regions" {
  description = "Droplet region"
  type        = list(string)
  default     = ["ams1", "nyc1"]
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
