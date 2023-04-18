
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
