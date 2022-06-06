resource "digitalocean_droplet" "aries-farmnet-a" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-farmnet-a"
  region = "nyc3"
  size   = "c-8"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
  ]
}
