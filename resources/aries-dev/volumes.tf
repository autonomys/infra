# DEVELOPMENT
resource "digitalocean_volume" "aries-dev-volume" {
  region                  = "nyc3"
  name                    = "aries-dev-volume"
  size                    = 1100
  initial_filesystem_type = "ext4"
  description             = "Extra volume for aries dev."
}

resource "digitalocean_volume_attachment" "aries-dev-volume" {
  droplet_id = digitalocean_droplet.aries-dev-nodes-farmer-relayer.id
  volume_id  = digitalocean_volume.aries-dev-volume.id
}
