resource "digitalocean_project" "block-archive" {
  name        = "block-archive"
  description = "Block Archive"
  purpose     = "Service or API"
  environment = "development"
  resources   = [digitalocean_droplet.subspace-nodes-relayer-backend-2021.urn]
}

