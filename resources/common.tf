terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Check the README for more info on set this variable.
variable "do_token" {}

# path to the ssh key that will be used to remote-exec commands
variable "pvt_key" {}

# Set DigitalOcean as provider
provider "digitalocean" {
  token = var.do_token
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

# add ssh keys as single var
locals {
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.ved-key.id
  ]
}
