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

# Set DigitalOcean as provider
provider "digitalocean" {
  token = var.do_token
}

# SSH team keys to be used on droplet access
data "digitalocean_ssh_key" "nazar-key" {
  name = "Nazar SSH Key"
}
data "digitalocean_ssh_key" "leo-key" {
  name = "Leo SSH Key"
}
data "digitalocean_ssh_key" "serge-key" {
  name = "Serge SSH Key"
}
data "digitalocean_ssh_key" "sam-key" {
  name = "Sam SSH Key"
}
