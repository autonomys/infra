resource "digitalocean_droplet" "gemini-2a-bootstrap-nodes" {
  count = length(var.bootstrap-node-regions) * var.bootstrap-nodes-per-region
  image  = "ubuntu-22-04-x64"
  name   = "gemini-2a-bootstrap-node-${count.index}-${var.bootstrap-node-regions[count.index % length(var.bootstrap-node-regions)]}"
  region = var.bootstrap-node-regions[count.index % length(var.bootstrap-node-regions)]
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_droplet" "gemini-2a-full-nodes" {
  count = length(var.rpc-node-regions) * var.rpc-nodes-per-region
  image  = "ubuntu-22-04-x64"
  name   = "gemini-2a-rpc-node-${count.index}-${var.rpc-node-regions[count.index % length(var.rpc-node-regions)]}"
  region = var.rpc-node-regions[count.index % length(var.rpc-node-regions)]
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

