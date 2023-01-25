resource "digitalocean_droplet" "bootstrap-nodes" {
  count    = length(var.bootstrap-node-config.regions) * var.bootstrap-node-config.nodes-per-region
  image    = "ubuntu-22-04-x64"
  name     = "${var.network-name}-bootstrap-node-${count.index}-${var.bootstrap-node-config.regions[count.index % length(var.bootstrap-node-config.regions)]}"
  region   = var.bootstrap-node-config.regions[count.index % length(var.bootstrap-node-config.regions)]
  size     = var.bootstrap-node-config.droplet_size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_droplet" "full-nodes" {
  count    = length(var.full-node-config.regions) * var.full-node-config.nodes-per-region
  image    = "ubuntu-22-04-x64"
  name     = "${var.network-name}-full-node-${count.index}-${var.full-node-config.regions[count.index % length(var.full-node-config.regions)]}"
  region   = var.full-node-config.regions[count.index % length(var.full-node-config.regions)]
  size     = var.full-node-config.droplet_size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_droplet" "rpc-nodes" {
  count    = length(var.rpc-node-config.regions) * var.rpc-node-config.nodes-per-region
  image    = "ubuntu-22-04-x64"
  name     = "${var.network-name}-rpc-node-${count.index}-${var.rpc-node-config.regions[count.index % length(var.rpc-node-config.regions)]}"
  region   = var.rpc-node-config.regions[count.index % length(var.rpc-node-config.regions)]
  size     = var.rpc-node-config.droplet_size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_droplet" "farmer-nodes" {
  count    = length(var.farmer-node-config.regions) * var.farmer-node-config.nodes-per-region
  image    = "ubuntu-22-04-x64"
  name     = "${var.network-name}-farmer-node-${count.index}-${var.farmer-node-config.regions[count.index % length(var.farmer-node-config.regions)]}"
  region   = var.farmer-node-config.regions[count.index % length(var.farmer-node-config.regions)]
  size     = var.farmer-node-config.droplet_size
  ssh_keys = local.ssh_keys
}

