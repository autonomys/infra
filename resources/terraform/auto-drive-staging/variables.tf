variable "staging_host_ipv4" {
  description = "Public IPv4 of the bare-metal host, which Terraform connects to over SSH."
  type        = string
}

variable "ssh_agent_identity" {
  description = "SSH key's public key that is loaded into SSH-Agent"
  type        = string
}

variable "auto_drive_repo_ref" {
  description = "Branch, tag or full SHA of autonomys/auto-drive to check out on the host. Supplies hasura's migrations and the auth and frontend build contexts."
  type        = string
  default     = "main"
}

variable "letsencrypt_email" {
  description = "Contact address Let's Encrypt uses for expiry and revocation notices"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare api token used by certbot for DNS-01"
  type        = string
  sensitive   = true
}
