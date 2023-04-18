variable "droplet_size" {
  description = "Droplet size"
  type        = string
  default     = "m6-2vcpu-16gb"
}

variable "deployment_color" {
  description = "Deployment environment"
  type        = string
  default     = "blue"
}

variable "regions" {
  description = "Droplet region"
  type        = list(string)
  default     = ["AMS1", "NYC1"]
}

variable "squid-archive-node-config" {
  description = "Squid Archive configuration"
  type = object({
    droplet-size     = string
    deployment-color = string
    domain-prefix    = string
    regions          = list(string)
    nodes-per-region = number
    docker-org       = string
    docker-tag       = string
    prune            = bool
    environment      = string
  })

  default = {
    droplet-size     = "m6-2vcpu-16gb"
    deployment-color = "blue"
    domain-prefix    = "archive"
    regions          = ["AMS3", "NYC1"]
    nodes-per-region = 1
    docker-org       = "subspace"
    docker-tag       = "gemini-3d"
    environment      = "staging"
    prune            = false
  }
}

variable "global-node-config" {
  description = "Block explorer backend configuration"
  type = object({
    cloudflare_api_token = string
    cloudflare_email     = string
    do_token             = string
    ssh_identity         = string
    datadog_api_key      = string
  })

  default = {
    cloudflare_api_token = ""
    cloudflare_email     = ""
    do_token             = ""
    ssh_identity         = ""
    datadog_api_key      = ""

  }
}