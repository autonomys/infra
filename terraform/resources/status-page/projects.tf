resource "digitalocean_project" "status-page" {
  name        = "status-page"
  description = "Website or blog / Project for status page"
  purpose     = "Website or blog"
  resources   = [digitalocean_droplet.status-droplet.urn]
}

