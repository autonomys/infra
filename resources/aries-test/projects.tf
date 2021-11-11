# TESTING
resource "digitalocean_project" "aries-test" {
  name        = "aries-test"
  description = "Subspace Aries Testing Resources."
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.aries-test-nodes-farmer-relayer.urn]
}
