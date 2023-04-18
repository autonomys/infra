locals {
  droplets_urn = flatten([
    [for droplet in digitalocean_droplet.explorer-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.archive-squid-nodes : droplet.urn],
  ])
}

resource "digitalocean_project" "explorers" {
  count       = length(local.droplets_urn) > 0 ? 1 : 0
  name        = "${var.network-name}-explorers"
  environment = "staging"
  description = "Subspace ${title(var.network-name)} blue-green explorers"
  purpose     = "Explorers"
  resources = flatten([
    [for droplet in digitalocean_droplet.explorer-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.archive-squid-nodes : droplet.urn],
  ])
}

