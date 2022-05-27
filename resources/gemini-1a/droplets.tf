resource "digitalocean_droplet" "gemini-1a" {
  count = length(var.droplet-regions) * var.droplets-per-region
  image  = "ubuntu-20-04-x64"
  name   = "gemini-1a-node-${count.index}-${var.droplet-regions[count.index % length(var.droplet-regions)]}"
  region = var.droplet-regions[count.index % length(var.droplet-regions)]
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}
