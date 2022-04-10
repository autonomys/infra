resource "digitalocean_droplet" "telemetry-subspace-frontend-backend" {
  image  = "ubuntu-20-04-x64"
  name   = "telemetry-subspace-frontend-backend"
  region = "nyc3"
  size   = "s-8vcpu-16gb"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.leo-key.id,
  ]
}
