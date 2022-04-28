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

resource "digitalocean_volume" "aries-test-b-volume-2" {
  region                  = "nyc3"
  name                    = "aries-test-b-volume-2"
  size                    = 1800
  initial_filesystem_type = "ext4"
  description             = "Extra volume for aries test b."
}

resource "digitalocean_volume_attachment" "aries-test-b-volume-2" {
  droplet_id = digitalocean_droplet.aries-test-b-nodes-farmer-relayer-2.id
  volume_id  = digitalocean_volume.aries-test-b-volume-2.id
}
