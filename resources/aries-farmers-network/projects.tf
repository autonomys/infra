resource "digitalocean_project" "aries-farmers-network" {
  name        = "aries-farmers-network"
  description = "Subspace Aries Farmers Network Resources."
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.aries-farmers-network-nodes.urn]
}
