resource "digitalocean_project" "aries-test-b" {
  name        = "aries-test-b"
  description = "Subspace Aries Testing Resources."
  purpose     = "Service or API"
  environment = "development"
  resources = [digitalocean_droplet.aries-test-b-nodes-farmer-relayer.urn, digitalocean_volume.aries-test-b-volume.urn,
    digitalocean_droplet.aries-test-b-nodes-farmer-relayer-2.urn,
  digitalocean_volume.aries-test-b-volume-2.urn, digitalocean_droplet.aries-farmers-network-b-nodes.urn]
}
