resource "digitalocean_droplet" "gemini-1b" {
  count = length(var.droplet-regions) * var.droplets-per-region
  image  = "ubuntu-20-04-x64"
  name   = "gemini-1b-node-${count.index}-${var.droplet-regions[count.index % length(var.droplet-regions)]}"
  region = var.droplet-regions[count.index % length(var.droplet-regions)]
  size   = var.droplet-size
  ssh_keys = [
    data.digitalocean_ssh_key.alexei2-key.id,
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.ved-key.id
  ]
}
