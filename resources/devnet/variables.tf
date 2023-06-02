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

variable "farmer-reward-address" {
  description = "Farmer's reward address"
  type        = string
}

variable "domain_id" {
  description = "Domain ID"
  type        = list(number)
  default     = [1, 2, 3]
}

variable "domain_labels" {
  description = "Tag of the domain to run"
  type        = list(string)
  default     = ["evm"]
}


variable "bootstrap_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = ["65.108.232.59"]
}

variable "full_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = [""]
}

variable "rpc_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = ["65.108.232.54"]
}

variable "domain_node_ips" {
  description = "IP of domain node"
  type        = list(string)
  default     = ["65.108.74.115"]
}

variable "farmer_node_ips" {
  description = "IP of boostrap node"
  type        = list(string)
  default     = ["65.108.232.15"]
}
