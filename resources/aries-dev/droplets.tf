resource "digitalocean_droplet" "aries-dev-nodes-farmer-relayer" {
  image  = "ubuntu-20-04-x64"
  name   = join("-", ["aries-dev-nodes-farmer-relayer", data.external.droplet_name.result.name])
  region = "sfo3"
  size   = "s-2vcpu-4gb"
}
