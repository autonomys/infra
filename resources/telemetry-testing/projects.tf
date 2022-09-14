resource "digitalocean_project" "telemetry-testing-subspace" {
  name        = "Telemetry Testing Subspace"
  purpose     = "Service or API"
  resources   = [digitalocean_droplet.telemetry-testing-subspace.urn]
}
