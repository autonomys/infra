locals {
  droplets_urn = flatten([
    [for droplet in digitalocean_droplet.squid-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.archive-nodes : droplet.urn],
  ])
}

resource "digitalocean_project" "squids" {
  count       = length(local.droplets_urn) > 0 ? 1 : 0
  name        = "${var.network-name}-${var.deployment-color}-squids"
  environment = "staging"
  description = "Subspace ${title(var.network-name)} blue-green squids"
  purpose     = "Explorers"
  resources = flatten([
    [for droplet in digitalocean_droplet.squid-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.archive-nodes : droplet.urn],
  ])
}
