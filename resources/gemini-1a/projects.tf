resource "digitalocean_project" "gemini-1a" {
  name        = "gemini-1a"
  description = "Subspace Gemini 1a"
  purpose     = "Testnet"
  environment = "Production"
  resources = flatten([
    [for droplet in digitalocean_droplet.gemini-1a: droplet.urn],
    [digitalocean_droplet.gemini-1a-temp.urn],
  ])
}


