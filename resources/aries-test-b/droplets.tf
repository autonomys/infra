resource "digitalocean_droplet" "aries-test-b-nodes-farmer-relayer" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-test-b-nodes-farmer-relayer"
  region = "nyc3"
  size   = "c-8"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
    # TODO: Add floating IP so that you can add this without changing the IP address
    # data.digitalocean_ssh_key.sam-key.id,
  ]
}

resource "digitalocean_droplet" "aries-test-b-nodes-farmer-relayer-2" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-test-b-nodes-farmer-relayer-2"
  region = "nyc3"
  size   = "c-8"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
    data.digitalocean_ssh_key.sam-key.id,
  ]
}

resource "digitalocean_droplet" "aries-farmers-network-b-nodes" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-farmers-network-b-nodes"
  region = "nyc3"
  size   = "s-4vcpu-8gb-intel"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
    # TODO: Add floating IP so that you can add this without changing the IP address
    # data.digitalocean_ssh_key.sam-key.id,
  ]
}
