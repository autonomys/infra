resource "digitalocean_project" "project" {
  name        = var.network-name
  environment = "Production"
  description = "Subspace ${title(var.network-name)} network"
  purpose     = "Blockchain"
  resources = flatten([
    [for droplet in digitalocean_droplet.full-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.bootstrap-nodes : droplet.urn],
    [for droplet in digitalocean_droplet.rpc-nodes : droplet.urn],
  ])
}

