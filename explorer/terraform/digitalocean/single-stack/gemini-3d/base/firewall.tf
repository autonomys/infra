locals {
  archive_node_firewall_list  = chunklist(digitalocean_droplet.archive-nodes.*.id, 10)
  squid_node_firewall_list = chunklist(digitalocean_droplet.squid-nodes.*.id, 10)
}

// looks like digital ocean do not support more than 10 droplets in a single firewall
// break it up into two sets

resource "digitalocean_firewall" "squid-node-firewall" {
  count = length(local.squid_node_firewall_list)
  name  = "${var.squid-node-config.network-name}-squid-node-firewall-${count.index}"

  droplet_ids = local.squid_node_firewall_list[count.index]

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

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "8080"
  #   source_addresses = ["0.0.0.0/0"]
  # }

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "4350"
  #   source_addresses = ["0.0.0.0/0"]
  # }

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "7070"
  #   source_addresses = ["0.0.0.0/0"]
  # }

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


resource "digitalocean_firewall" "archive-node-firewall" {
  count = length(local.archive_node_firewall_list)
  name  = "${var.archive-node-config.network-name}-archive-node-firewall-${count.index}"

  droplet_ids = local.archive_node_firewall_list[count.index]

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

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "8888"
  #   source_addresses = ["0.0.0.0/0"]
  # }

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "4444"
  #   source_addresses = ["0.0.0.0/0"]
  # }

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "8080"
  #   source_addresses = ["0.0.0.0/0"]
  # }

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "7070"
  #   source_addresses = ["0.0.0.0/0"]
  # }

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
