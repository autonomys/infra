resource "digitalocean_droplet" "telemetry-testing-subspace" {
  image  = "ubuntu-20-04-x64"
  name   = "telemetry-testing-subspace"
  region = "nyc3"
  size   = "s-8vcpu-16gb"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.i1i1-key.id,
  ]
}
