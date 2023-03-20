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

variable "droplet-size" {
  description = "Droplet size"
  type        = string
  default     = "m6-2vcpu-16gb"
}

variable "hetzner_bootstrap_node_ips" {
  description = "Hetzner bootstrap ip v4"
  type        = list(string)
}

variable "hetzner_full_node_ips" {
  description = "Hetzner full node ip v4"
  type        = list(string)
}

variable "hetzner_rpc_node_ips" {
  description = "Hetzner rpc node ip v4"
  type        = list(string)
}
