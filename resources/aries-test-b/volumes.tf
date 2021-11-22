resource "digitalocean_volume" "aries-test-b-volume" {
  region                  = "sfo3"
  name                    = "aries-test-relayer-data-b"
  size                    = 1000
  initial_filesystem_type = "ext4"
  description             = "Extra volume for relayer data initial imports."
}

resource "digitalocean_volume_attachment" "aries-test-b-volume" {
  droplet_id = digitalocean_droplet.aries-test-b-nodes-farmer-relayer.id
  volume_id  = digitalocean_volume.aries-test-b-volume.id
}
