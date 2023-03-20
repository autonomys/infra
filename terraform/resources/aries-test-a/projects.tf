resource "digitalocean_project" "aries-test-a" {
  name        = "aries-test-a"
  description = "Subspace Aries Testing Resources."
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.aries-test-a-nodes-farmer-relayer.urn]
}
