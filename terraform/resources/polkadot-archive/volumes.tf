resource "digitalocean_volume" "polkadot-archive-volume" {
  region                  = "nyc3"
  name                    = "polkadot-archive-volume"
  size                    = 500
  initial_filesystem_type = "ext4"
}

resource "digitalocean_volume_attachment" "polkadot-archive-volume" {
  droplet_id = digitalocean_droplet.polkadot-archive-droplet.id
  volume_id  = digitalocean_volume.polkadot-archive-volume.id
}
