resource "digitalocean_project" "gemini-2a" {
  name        = "gemini-2a"
  description = "Subspace Gemini 2a"
  purpose     = "Testnet"
  environment = "Production"
  resources = flatten([
    [for droplet in digitalocean_droplet.gemini-2a-full-nodes: droplet.urn],
    [for droplet in digitalocean_droplet.gemini-2a-bootstrap-nodes: droplet.urn],
  ])
}


