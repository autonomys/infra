locals {
  full_node_firewall_list      = chunklist(digitalocean_droplet.full-nodes.*.id, 10)
  bootstrap_node_firewall_list = chunklist(digitalocean_droplet.bootstrap-nodes.*.id, 10)
  rpc_node_firewall_list       = chunklist(digitalocean_droplet.rpc-nodes.*.id, 10)
}

// looks like digital ocean do not support more than 10 droplets in a single firewall
// break it up into two sets
resource "digitalocean_firewall" "full-node-firewall" {
  count = length(local.full_node_firewall_list)
  name  = "${var.network-name}-full-node-firewall-${count.index}"

  droplet_ids = local.full_node_firewall_list[count.index]

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

resource "digitalocean_firewall" "boostrap-node-firewall" {
  count = length(local.bootstrap_node_firewall_list)
  name  = "${var.network-name}-bootstrap-node-firewall-${count.index}"

  droplet_ids = local.bootstrap_node_firewall_list[count.index]

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

resource "digitalocean_firewall" "rpc-node-firewall" {
  count = length(local.rpc_node_firewall_list)
  name  = "${var.network-name}-rpc-node-firewall-${count.index}"

  droplet_ids = local.rpc_node_firewall_list[count.index]

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

