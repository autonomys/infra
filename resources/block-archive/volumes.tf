resource "digitalocean_volume" "volume-sfo3-03" {
  region                  = "sfo3"
  name                    = "volume-sfo3-03"
  size                    = 250
  initial_filesystem_type = "ext4"
}

resource "digitalocean_volume_attachment" "volume-sfo3-03" {
  droplet_id = digitalocean_droplet.subspace-nodes-relayer-backend-2021.id
  volume_id  = digitalocean_volume.volume-sfo3-03.id
}
