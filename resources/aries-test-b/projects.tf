resource "digitalocean_project" "aries-test-b" {
  name        = "aries-test-b"
  description = "Subspace Aries Testing Resources."
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.aries-test-b-nodes-farmer-relayer.urn]
}
