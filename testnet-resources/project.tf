# Project
resource "digitalocean_project" "testnet-resources" {
  name        = "testnet-resources"
  description = "Project to manage testnet resources for subspace projects"
  purpose     = "Service or API"
  environment = "production"
  resources   = [digitalocean_droplet.relayer-app-backend.urn, digitalocean_droplet.public-rpc-1.urn]
}
