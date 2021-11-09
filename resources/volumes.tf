
# DEVELOPMENT
resource "digitalocean_volume" "aries-dev-relayer-volume" {
  region                  = "sfo3"
  name                    = "aries-dev-relayer-data-250gb"
  size                    = 250
  initial_filesystem_type = "ext4"
  description             = "Extra volume for relayer data initial imports."
}

resource "digitalocean_volume_attachment" "aries-dev-relayer-volume" {
  droplet_id = digitalocean_droplet.aries-dev-nodes-farmer-relayer.id
  volume_id  = digitalocean_volume.aries-dev-relayer-volume.id
}

# TESTING
resource "digitalocean_volume" "aries-test-relayer-volume" {
  region                  = "sfo3"
  name                    = "aries-test-relayer-data-250gb"
  size                    = 250
  initial_filesystem_type = "ext4"
  description             = "Extra volume for relayer data initial imports."
}

resource "digitalocean_volume_attachment" "aries-test-relayer-volume" {
  droplet_id = digitalocean_droplet.aries-test-nodes-farmer-relayer.id
  volume_id  = digitalocean_volume.aries-test-relayer-volume.id
}
