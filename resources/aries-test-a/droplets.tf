resource "digitalocean_droplet" "aries-test-a-nodes-farmer-relayer" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-test-a-nodes-farmer-relayer"
  region = "nyc3"
  size   = "c-8"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
  ]
}

resource "digitalocean_droplet" "aries-farmers-network-a-nodes" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-farmers-network-a-nodes"
  region = "nyc3"
  size   = "s-4vcpu-8gb-intel"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
  ]
}
