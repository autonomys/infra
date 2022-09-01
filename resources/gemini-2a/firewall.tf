locals {
  rpc_node_firewall_set = [
    slice([for droplet in digitalocean_droplet.gemini-2a-rpc-nodes: droplet.id], 0, 6),
    slice([for droplet in digitalocean_droplet.gemini-2a-rpc-nodes: droplet.id], 6, 12)
  ]
}

// looks like digital ocean do not support more than 10 droplets in a single firewall
// break it up into two sets
resource "digitalocean_firewall" "gemini-2a-rpc-node-firewall" {
  count = length(local.rpc_node_firewall_set)
  name = "gemini-2a-rpc-node-firewall-${count.index}"

  droplet_ids = local.rpc_node_firewall_set[count.index]

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

resource "digitalocean_firewall" "gemini-2a-boostrap-node-firewall" {
  count = length(digitalocean_droplet.gemini-2a-bootstrap-nodes)
  name = "gemini-2a-bootstrap-node-firewall-${count.index}"

  droplet_ids = [for droplet in digitalocean_droplet.gemini-2a-bootstrap-nodes: droplet.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
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

