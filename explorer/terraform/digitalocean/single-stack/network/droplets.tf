
resource "digitalocean_droplet" "squid-archive-nodes" {
  count    = length(var.squid-archive-node-config.regions) * var.squid-archive-node-config.nodes-per-region
  image    = "ubuntu-22-04-x64"
  name     = "${var.network-name}-archive-node-${count.index}-${var.squid-archive-node-config.regions[count.index % length(var.squid-archive-node-config.regions)]}"
  region   = var.squid-archive-node-config.regions[count.index % length(var.squid-archive-node-config.regions)]
  size     = var.squid-archive-node-config.droplet_size
  ssh_keys = local.ssh_keys
}


resource "digitalocean_droplet" "explorer-nodes" {
  count    = length(var.explorer-node-config.regions) * var.explorer-node-config.nodes-per-region
  image    = "ubuntu-22-04-x64"
  name     = "${var.network-name}-explorer-node-${count.index}-${var.explorer-node-config.regions[count.index % length(var.explorer-node-config.regions)]}"
  region   = var.explorer-node-config.regions[count.index % length(var.explorer-node-config.regions)]
  size     = var.explorer-node-config.droplet_size
  ssh_keys = local.ssh_keys
}