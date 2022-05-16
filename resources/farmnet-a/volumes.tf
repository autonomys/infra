resource "digitalocean_volume" "aries-farmnet-a" {
  region                  = "nyc3"
  name                    = "farmnet-a-volume"
  size                    = 1800
  initial_filesystem_type = "ext4"
  description             = "Extra volume for relaynet a."
}

resource "digitalocean_volume_attachment" "aries-farmnet-a" {
  droplet_id = digitalocean_droplet.aries-farmnet-a.id
  volume_id  = digitalocean_volume.aries-farmnet-a.id
}
