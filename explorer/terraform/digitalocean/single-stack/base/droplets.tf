resource "digitalocean_droplet" "archive-squid-nodes" {
  count    = length(var.archive-squid-node-config.regions) * var.archive-squid-node-config.nodes-per-region
  image    = "ubuntu-22-10-x64"
  name     = "${var.network-name}-archive-node-${count.index}-${var.archive-squid-node-config.regions[count.index % length(var.archive-squid-node-config.regions)]}"
  region   = var.archive-squid-node-config.regions[count.index % length(var.archive-squid-node-config.regions)]
  size     = var.archive-squid-node-config.droplet_size
  ssh_keys = local.ssh_keys
  user_data = file("${var.path-to-configs}/userdata.tpl")
}

resource "digitalocean_volume" "archive-squid-nodes-additional-volume" {
  count    = length(var.archive-squid-node-config.regions) * var.archive-squid-node-config.nodes-per-region
  region                  = var.archive-squid-node-config.regions[count.index % length(var.archive-squid-node-config.regions)]
  name                    = "${var.network-name}-archive-squid-node-${count.index}-${var.archive-squid-node-config.regions[count.index % length(var.archive-squid-node-config.regions)]}-vol"
  size                    = 100
  initial_filesystem_type = "ext4"
  description             = "archive_squid mount"
}

resource "digitalocean_volume_attachment" "archive-squid-nodes-volume-attachment" {
  count    = length(var.archive-squid-node-config.regions) * var.archive-squid-node-config.nodes-per-region
  droplet_id = digitalocean_droplet.archive-squid-nodes[count.index].id
  volume_id  = digitalocean_volume.archive-squid-nodes-additional-volume[count.index].id
}

resource "digitalocean_droplet" "explorer-nodes" {
  count    = length(var.explorer-node-config.regions) * var.explorer-node-config.nodes-per-region
  image    = "ubuntu-22-10-x64"
  name     = "${var.network-name}-explorer-node-${count.index}-${var.explorer-node-config.regions[count.index % length(var.explorer-node-config.regions)]}"
  region   = var.explorer-node-config.regions[count.index % length(var.explorer-node-config.regions)]
  size     = var.explorer-node-config.droplet_size
  ssh_keys = local.ssh_keys
  user_data = file("${var.path-to-configs}/userdata.tpl")
}

resource "digitalocean_volume" "explorer-nodes-additional-volume" {
  count    = length(var.explorer-node-config.regions) * var.explorer-node-config.nodes-per-region
  region                  = var.explorer-node-config.regions[count.index % length(var.explorer-node-config.regions)]
  name                    = "${var.network-name}-explorer-node-${count.index}-${var.explorer-node-config.regions[count.index % length(var.explorer-node-config.regions)]}-vol"
  size                    = 100
  initial_filesystem_type = "ext4"
  description             = "explorer_squid mount"
}

resource "digitalocean_volume_attachment" "explorer-nodes-volume-attachment" {
  count    = length(var.explorer-node-config.regions) * var.explorer-node-config.nodes-per-region
  droplet_id = digitalocean_droplet.explorer-nodes[count.index].id
  volume_id  = digitalocean_volume.explorer-nodes-additional-volume[count.index].id
}
