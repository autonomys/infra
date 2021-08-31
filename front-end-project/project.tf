# Project
resource "digitalocean_project" "dev-front-end" {
  name        = "dev-front-end"
  description = "Project to manage front end resources for development stage"
  purpose     = "Service or API"
  environment = "Development"
  resources   = [digitalocean_droplet.polkascan.urn, digitalocean_droplet.polkadot-apps.urn]
}
