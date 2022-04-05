resource "digitalocean_project" "telemetry-subspace" {
  name        = "Telemetry Subspace"
  purpose     = "Service or API"
  resources   = [digitalocean_droplet.telemetry-subspace-frontend-backend.urn]
}
