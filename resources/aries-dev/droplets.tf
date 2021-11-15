resource "digitalocean_droplet" "aries-dev-nodes-farmer-relayer" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-dev-nodes-farmer-relayer-08112021"
  region = "sfo3"
  size   = "s-4vcpu-8gb-intel"
}
