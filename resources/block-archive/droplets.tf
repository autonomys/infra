resource "digitalocean_droplet" "subspace-nodes-relayer-backend-2021" {
  image  = "ubuntu-20-04-x64"
  name   = "subspace-nodes-relayer-backend-2021"
  region = "sfo3"
  size   = "s-2vcpu-4gb-intel"
}
