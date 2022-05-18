resource "digitalocean_project" "gemini-1" {
  name        = "gemini-1"
  description = "Subspace Gemini testnet"
  purpose     = "Testnet"
  environment = "Production"
  resources = flatten([
    [for droplet in digitalocean_droplet.gemini-1: droplet.id],
    [for vol in digitalocean_volume.gemini-1: vol.id],
    [for vol_at in digitalocean_volume_attachment.gemini-1: vol_at.id],
  ])
}


