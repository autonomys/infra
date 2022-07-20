resource "digitalocean_project" "tf_refactoring" {
  name        = "tf_refactoring"
  description = "Subspace Gemini 1b"
  purpose     = "Testnet"
  environment = "Production"
  resources = [for droplet in digitalocean_droplet.gemini-1b: droplet.urn]
#  resources = flatten([
#    [for droplet in digitalocean_droplet.gemini-1b-test: droplet.urn],
#    [for droplet in digitalocean_droplet.gemini-1b-extra: droplet.urn],
#    [for droplet in digitalocean_droplet.gemini-1b-extra-US: droplet.urn],
#  ])
}


