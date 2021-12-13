resource "digitalocean_volume" "aries-farmers-network-volume" {
  region                  = "nyc3"
  name                    = "aries-farmers-network-volume"
  size                    = 1100
  initial_filesystem_type = "ext4"
  description             = "Extra volume for aries farmers network."
}

resource "digitalocean_volume_attachment" "aries-test-b-volume" {
  droplet_id = digitalocean_droplet.aries-farmers-network-nodes.id
  volume_id  = digitalocean_volume.aries-farmers-network-volume.id
}
