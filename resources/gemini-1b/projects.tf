resource "digitalocean_project" "gemini-1b" {
  name        = "gemini-1b"
  description = "Subspace Gemini 1b"
  purpose     = "Testnet"
  environment = "Production"
  resources = [for droplet in digitalocean_droplet.gemini-1b: droplet.urn]
}


