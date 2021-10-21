data "digitalocean_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

resource "digitalocean_droplet" "relayer-app-backend" {
  image  = "ubuntu-20-04-x64"
  name   = join("-", [data.external.droplet_name.result.name, "relayer-app-backend"])
  region = "nyc1"
  size   = "s-2vcpu-4gb"
  /* ssh_keys = [
    data.digitalocean_ssh_key.ssh_key.id
  ]*/
}

resource "digitalocean_droplet" "public-rpc-1" {

  image  = "ubuntu-20-04-x64"
  name   = join("-", [data.external.droplet_name.result.name, "public-rpc-1"])
  region = "nyc1"
  size   = "s-2vcpu-4gb"
  /* ssh_keys = [
    data.digitalocean_ssh_key.ssh_key.id
  ]*/
}
