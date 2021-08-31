data "digitalocean_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

resource "digitalocean_droplet" "polkascan" {

  image  = "ubuntu-20-04-x64"
  name   = data.external.droplet_name.result.name + "-polkascan"
  region = "nyc1"
  size   = "s-2vcpu-4gb"
  /* ssh_keys = [
    data.digitalocean_ssh_key.ssh_key.id
  ]*/
}

resource "digitalocean_droplet" "polkadot-apps" {

  image  = "ubuntu-20-04-x64"
  name   = data.external.droplet_name.result.name + "-polkadot-apps"
  region = "nyc1"
  size   = "s-2vcpu-4gb"
  /* ssh_keys = [
    data.digitalocean_ssh_key.ssh_key.id
  ]*/
}
