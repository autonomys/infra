resource "digitalocean_project" "aries-farmnet-a" {
  name        = "aries-farmnet-a"
  description = "Subspace Aries Testing Resources."
  purpose     = "Service or API"
  environment = "development"
  resources = [digitalocean_droplet.aries-farmnet-a.urn, digitalocean_volume.aries-farmnet-a.urn,
  ]
}



