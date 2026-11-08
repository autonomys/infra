variable "host_ipv4" {
  description = "Public IPv4 of the bare-metal host, which Terraform connects to over SSH. Sensitive so plans don't print the origin behind the proxied records."
  type        = string
  sensitive   = true
}

variable "ssh_agent_identity" {
  description = "Agent key Terraform offers first: its comment as `ssh-add -l` shows it, or the absolute path of its key file. The public key text itself matches nothing."
  type        = string
}

variable "letsencrypt_email" {
  description = "Contact address registered with the Let's Encrypt account"
  type        = string
}
