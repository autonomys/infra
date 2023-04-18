locals {
  droplets_urn = flatten([
    [for droplet in digitalocean_droplet.explorer-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.archive-squid-nodes : droplet.urn],
  ])
}

resource "digitalocean_project" "project" {
  count       = length(local.droplets_urn) > 0 ? 1 : 0
  name        = var.network-name
  environment = "Production"
  description = "Subspace ${title(var.network-name)} explorers"
  purpose     = "Blockchain"
  resources = flatten([
    [for droplet in digitalocean_droplet.explorer-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.archive-squid-nodes : droplet.urn],
  ])
}

