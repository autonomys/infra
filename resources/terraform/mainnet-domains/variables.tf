variable "cloudflare_api_token" {
  description = "Cloudflare api token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare zone specific accountID"
  type        = string
  sensitive   = true
}

variable "disk_volume_type" {
  description = "EBS disk volume type"
  type        = string
  default     = "gp3"
}

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

variable "aws_ssh_key_name" {
  description = "AWS deployer's SSH key"
  type        = string
}

variable "ssh_agent_identity" {
  description = "AWS SSH key's public key that is loaded into SSH-Agent"
  type        = string
}

variable "new_relic_api_key" {
  description = "New relic API Key"
  type        = string
  sensitive   = true
}

variable "bare_domain_operator_ipv4" {
  description = "List of Bare metal IPs for domain operators"
  type        = map(string)
}
