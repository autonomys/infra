locals {
  firewall_sets = [
    slice([for droplet in digitalocean_droplet.gemini-1b: droplet.id], 0, 6),
    slice([for droplet in digitalocean_droplet.gemini-1b: droplet.id], 6, 12)
  ]
}

// looks like digital ocean do not support more than 10 droplets in a single firewall
// break it up into two sets
resource "digitalocean_firewall" "gemini-1b-firewall" {
  count = length(local.firewall_sets)
  name = "gemini-1b-firewall-${count.index}"

  droplet_ids = local.firewall_sets[count.index]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "30333"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }
}

