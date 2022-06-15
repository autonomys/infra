resource "digitalocean_project" "x-net" {
  name        = "x-net"
  description = "Subspace X-net"
  purpose     = "Testnet"
  environment = "Production"
  resources = [
    digitalocean_droplet.x-net-rpc.urn,
    digitalocean_droplet.x-net-farmer.urn,
    digitalocean_droplet.x-net-executor.urn
  ]
}


