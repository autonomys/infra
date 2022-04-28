resource "digitalocean_volume" "aries-test-b-volume" {
  region                  = "nyc3"
  name                    = "aries-test-b-volume"
  size                    = 1800
  initial_filesystem_type = "ext4"
  description             = "Extra volume for aries test b."
}

resource "digitalocean_volume_attachment" "aries-test-b-volume" {
  droplet_id = digitalocean_droplet.aries-test-b-nodes-farmer-relayer.id
  volume_id  = digitalocean_volume.aries-test-b-volume.id
}

resource "digitalocean_volume" "aries-relaynet-a" {
  region                  = "nyc3"
  name                    = "relaynet-a-volume"
  size                    = 1800
  initial_filesystem_type = "ext4"
  description             = "Extra volume for relaynet a."
}

resource "digitalocean_volume_attachment" "aries-relaynet-a" {
  droplet_id = digitalocean_droplet.aries-relaynet-a.id
  volume_id  = digitalocean_volume.aries-relaynet-a.id
}
