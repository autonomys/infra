resource "digitalocean_droplet" "aries-test-b-nodes-farmer-relayer" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-test-nodes-farmer-relayer-b-16112021"
  region = "sfo3"
  size   = "c-8"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
  ]
}
