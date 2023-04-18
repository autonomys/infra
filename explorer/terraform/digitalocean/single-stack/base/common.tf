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

# SSH team keys to be used on droplet access
data "digitalocean_ssh_key" "nazar-key" {
  name = "Nazar SSH Key"
}
data "digitalocean_ssh_key" "serge-key" {
  name = "Serge SSH Key"
}
data "digitalocean_ssh_key" "ved-key" {
  name = "Ved SSH Key"
}
data "digitalocean_ssh_key" "i1i1-key" {
  name = "Ivan SSH Key"
}

data "digitalocean_ssh_key" "muhammad-key" {
  name = "Muhammad SSH Key"
}

# add ssh keys as single var
locals {
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.ved-key.id,
    data.digitalocean_ssh_key.muhammad-key.id,
  ]
}
