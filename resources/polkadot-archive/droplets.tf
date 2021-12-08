resource "digitalocean_droplet" "polkadot-archive-droplet" {
  image  = "ubuntu-20-04-x64"
  name   = "polkadot-archive-droplet"
  region = "nyc3"
  size   = "s-4vcpu-8gb-intel"
}
