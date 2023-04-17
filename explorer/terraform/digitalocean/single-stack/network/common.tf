terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.18.0"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
}

provider "docker" {
  host = "tcp://localhost:2375"
}

# Set DigitalOcean as provider
provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}

variable "do_token" {
  type = string
  description = "Digital ocean API key"
}

variable "ssh_identity" {
  type = string
  description = "SSH agent identity to use to connect to remote host"
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
  name = "Muhammad-SSH-key"
}

# add ssh keys as single var
locals {
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.ved-key.id,
    data.digitalocean_ssh_key.muhammad-key.id
  ]
}
