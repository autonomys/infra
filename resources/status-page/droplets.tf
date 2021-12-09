resource "digitalocean_droplet" "status-droplet" {
  image  = "ubuntu-20-04-x64"
  name   = "status-droplet"
  region = "nyc1"
  size   = "s-1vcpu-2gb"
}
