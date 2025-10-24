variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
  default     = null
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
  default     = null
}

variable "new_relic_api_key" {
  description = "New relic API Key"
  type        = string
  sensitive   = true
}

variable "cloudflare_domain_fqdn" {
  description = "Domain FQDN for DNS records"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID specific to Zone ID"
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
  default     = null
}

variable "vpc_cidr_block" {
  description = "AWS VPC's CIDR"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "AWS availability Zone"
  type        = string
  default     = null
}

// TODO: update this to single subnet cidr
variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR values"
  type        = list(string)
  default     = []
}

variable "aws_ssh_key_name" {
  description = "AWS deployer's SSH key"
  type        = string
  default     = null
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

variable "deployment_name" {
  description = "Name of the deployment. Ex: labs, foundation etc..."
  type        = string
  default     = null
}

variable "consensus-bootstrap-node-config" {
  description = "Consensus Bootstrap node deployment config"
  type = object({
    instance-type = string
    bootstrap-nodes = list(object({
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
    }))
    genesis-hash     = string
    disk-volume-size = number
    disk-volume-type = string
  })
  default = null
}

variable "bare-consensus-bootstrap-node-config" {
  description = "Bare Consensus Bootstrap node deployment config"
  type = object({
    bootstrap-nodes = list(object({
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
      ipv4          = string
    }))
    genesis-hash = string
  })
  default = null
}

variable "consensus-rpc-node-config" {
  description = "Consensus RPC node deployment config"
  type = object({
    instance-type        = string
    dns-prefix           = string
    enable-reverse-proxy = bool
    enable-load-balancer = bool
    rpc-nodes = list(object({
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
    }))
    disk-volume-size = number
    disk-volume-type = string
  })
  default = null
}

variable "bare-consensus-rpc-node-config" {
  description = "Consensus RPC node deployment config for bare servers"
  type = object({
    dns-prefix           = string
    enable-reverse-proxy = bool
    enable-load-balancer = bool
    rpc-nodes = list(object({
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
      ipv4          = string
    }))
  })
  default = null
}

variable "farmer-node-config" {
  description = "Farmer and Node configuration. Requires an NVME instance storage and not EBS"
  type = object({
    instance-type = string
    farmer-nodes = list(object({
      docker-tag             = string
      reserved-only          = bool
      plot-size              = string
      cache-percentage       = number
      reward-address         = string
      force-block-production = bool
      faster-sector-plotting = bool
      index                  = number
      sync-mode              = string
      // also run farmer node as timekeeper
      // should be used only for dev network where
      // dedicated timekeepers are deployed
      is-timekeeper = bool
    }))
  })
  default = null
}

variable "timekeeper-node-config" {
  description = "Timekeeper node deployment config for Bare servers"
  type = object({
    timekeeper-nodes = list(object({
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
      ipv4          = string
    }))
  })
  default = null
}

variable "domain-bootstrap-node-config" {
  description = "Domain Bootstrap node deployment config"
  type = object({
    instance-type = string
    bootstrap-nodes = list(object({
      domain-id     = number
      domain-name   = string
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
    }))
    disk-volume-size = number
    disk-volume-type = string
  })
  default = null
}

variable "bare-domain-bootstrap-node-config" {
  description = "Domain Bootstrap node deployment config for Bare servers"
  type = object({
    bootstrap-nodes = list(object({
      domain-id     = number
      domain-name   = string
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
      ipv4          = string
    }))
  })
  default = null
}

variable "domain-rpc-node-config" {
  description = "Domain RPC node deployment config"
  type = object({
    instance-type        = string
    enable-reverse-proxy = bool
    enable-load-balancer = bool
    rpc-nodes = list(object({
      domain-id     = number
      domain-name   = string
      docker-tag    = string
      reserved-only = bool
      index         = number
      sync-mode     = string
      eth-cache     = bool
    }))
    disk-volume-size = number
    disk-volume-type = string
  })
  default = null
}

variable "domain-operator-node-config" {
  description = "Domain Operator node deployment config"
  type = object({
    instance-type = string
    operator-nodes = list(object({
      domain-id     = number
      domain-name   = string
      docker-tag    = string
      reserved-only = bool
      operator-id   = number
      index         = number
      sync-mode     = string
    }))
    disk-volume-size = number
    disk-volume-type = string
  })
  default = null
}

variable "bare-domain-operator-node-config" {
  description = "Domain Operator node deployment config for Bare servers"
  type = object({
    operator-nodes = list(object({
      domain-id     = number
      domain-name   = string
      docker-tag    = string
      reserved-only = bool
      operator-id   = number
      index         = number
      sync-mode     = string
      ipv4          = string
    }))
  })
  default = null
}
