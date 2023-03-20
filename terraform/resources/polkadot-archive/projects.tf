resource "digitalocean_project" "polkadot-archive" {
  name        = "polkadot-archive"
  description = ""
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.polkadot-archive-droplet.urn]
}

