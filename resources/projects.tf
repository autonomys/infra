# DEVELOPMENT
resource "digitalocean_project" "aries-dev" {
  name        = "aries-dev"
  description = "Subspace Aries Development Resources."
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.aries-dev-nodes-farmer-relayer.urn]
}

# TESTING
resource "digitalocean_project" "aries-test" {
  name        = "aries-test"
  description = "Subspace Aries Testing Resources."
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.aries-test-nodes-farmer-relayer.urn]
}
