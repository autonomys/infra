resource "digitalocean_droplet" "squid-nodes" {
  count     = length(var.squid-node-config.regions) * var.squid-node-config.nodes-per-region
  image     = "ubuntu-22-10-x64"
  name      = "${var.archive-node-config.network-name}-squid-node-${count.index}-${var.squid-node-config.regions[count.index % length(var.squid-node-config.regions)]}"
  region    = var.squid-node-config.regions[count.index % length(var.squid-node-config.regions)]
  size      = var.squid-node-config.droplet_size
  ssh_keys  = local.ssh_keys
}

resource "digitalocean_volume" "squid-nodes-additional-volume" {
  count                   = length(var.squid-node-config.regions) * var.squid-node-config.nodes-per-region
  region                  = var.squid-node-config.regions[count.index % length(var.squid-node-config.regions)]
  name                    = "${var.archive-node-config.network-name}-squid-node-${count.index}-${var.squid-node-config.regions[count.index % length(var.squid-node-config.regions)]}-vol"
  size                    = var.squid-node-config.disk-volume-size
  initial_filesystem_type = var.squid-node-config.disk-volume-type
  description             = "squid mount"
}

resource "digitalocean_volume_attachment" "squid-nodes-volume-attachment" {
  count      = length(var.squid-node-config.regions) * var.squid-node-config.nodes-per-region
  droplet_id = digitalocean_droplet.squid-nodes[count.index].id
  volume_id  = digitalocean_volume.squid-nodes-additional-volume[count.index].id
}

resource "digitalocean_droplet" "archive-nodes" {
  count     = length(var.archive-node-config.regions) * var.archive-node-config.nodes-per-region
  image     = "ubuntu-22-10-x64"
  name      = "${var.archive-node-config.network-name}-archive-node-${count.index}-${var.archive-node-config.regions[count.index % length(var.archive-node-config.regions)]}"
  region    = var.archive-node-config.regions[count.index % length(var.archive-node-config.regions)]
  size      = var.archive-node-config.droplet_size
  ssh_keys  = local.ssh_keys
}

resource "digitalocean_volume" "archive-nodes-additional-volume" {
  count                   = length(var.archive-node-config.regions) * var.archive-node-config.nodes-per-region
  region                  = var.archive-node-config.regions[count.index % length(var.archive-node-config.regions)]
  name                    = "${var.archive-node-config.network-name}-archive-node-${count.index}-${var.archive-node-config.regions[count.index % length(var.archive-node-config.regions)]}-vol"
  size                    = var.archive-node-config.disk-volume-size
  initial_filesystem_type = var.archive-node-config.disk-volume-type
  description             = "archive mount"
}

resource "digitalocean_volume_attachment" "archive-nodes-volume-attachment" {
  count      = length(var.archive-node-config.regions) * var.archive-node-config.nodes-per-region
  droplet_id = digitalocean_droplet.archive-nodes[count.index].id
  volume_id  = digitalocean_volume.archive-nodes-additional-volume[count.index].id
}

