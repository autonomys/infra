# DEVELOPMENT
resource "digitalocean_volume" "aries-dev-relayer-volume" {
  region                  = "nyc3"
  name                    = "aries-dev-relayer-volume"
  size                    = 1100
  initial_filesystem_type = "ext4"
  description             = "Extra volume for relayer data initial imports."
}

resource "digitalocean_volume_attachment" "aries-dev-relayer-volume" {
  droplet_id = digitalocean_droplet.aries-dev-nodes-farmer-relayer.id
  volume_id  = digitalocean_volume.aries-dev-relayer-volume.id
}
