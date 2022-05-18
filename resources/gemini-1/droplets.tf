resource "digitalocean_droplet" "gemini-1" {
  count = length(var.droplet-regions)
  image  = "ubuntu-20-04-x64"
  name   = "gemini-node-farmer"
  region = var.droplet-regions[count.index]
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_volume" "gemini-1" {
  count = length(var.droplet-regions)
  region = var.droplet-regions[count.index]
  name  = "gemini-1-volume"
  size = 1000 # ~1 terrabytes
  initial_filesystem_type = "ext4"
  description= "Extra volume for Gemini-1-node"
}

resource "digitalocean_volume_attachment" "gemini-1" {
  count = length(var.droplet-regions)
  droplet_id = digitalocean_droplet.gemini-1[count.index].id
  volume_id  = digitalocean_volume.gemini-1[count.index].id
}
