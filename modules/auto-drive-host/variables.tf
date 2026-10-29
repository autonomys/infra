variable "deployer" {
  description = "Deployer specific details"
  type = object({
    ssh_user           = string
    ssh_agent_identity = string
    path_to_scripts    = string
  })
}

variable "instance" {
  description = "Auto-drive single-host deployment details"
  type = object({
    ipv4                = string
    hostname            = string
    primary_domain      = string
    download_domain     = string
    auto_drive_repo_ref = string
  })
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
