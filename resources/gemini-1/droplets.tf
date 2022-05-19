resource "digitalocean_droplet" "gemini-1" {
  count = length(var.droplet-regions)
  image  = "ubuntu-20-04-x64"
  name   = "gemini-1-node-${count.index}-${var.droplet-regions[count.index]}"
  region = var.droplet-regions[count.index]
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}
