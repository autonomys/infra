resource "digitalocean_droplet" "aries-farmers-network-nodes" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-farmers-network-nodes"
  region = "nyc3"
  size   = "c-8"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
  ]
}
