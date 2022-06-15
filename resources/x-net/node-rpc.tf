resource "digitalocean_droplet" "x-net-rpc" {
  image  = "ubuntu-20-04-x64"
  name   = "x-net-rpc"
  region = var.droplet-region
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "x-net-rpc" {
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "rpc.x-net"
  value   = digitalocean_droplet.x-net-rpc.ipv4_address
  type    = "A"
}

resource "digitalocean_firewall" "x-net-rpc-firewall" {
  name = "x-net-rpc-firewall"

  droplet_ids = [digitalocean_droplet.x-net-rpc.id]

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

locals {
  rpc_deployment_version = 1
}

resource "null_resource" "start_rpc_node" {
  depends_on = [null_resource.setup_nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.rpc_deployment_version
  }

  connection {
    host = digitalocean_droplet.x-net-rpc.ipv4_address
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "2m"
  }

  # copy node keys file
  provisioner "file" {
    source = "./node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy compose file
  provisioner "file" {
    source = "../../services/x-net/setup_rpc_compose.sh"
    destination = "/subspace/setup_rpc_compose.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "docker compose -f /subspace/docker-compose.yml down",
      "echo NODE_KEY=$(sed -nr 's/NODE_0_KEY=//p' /subspace/node_keys.txt) > /subspace/.env",
      "sudo chmod +x /subspace/setup_rpc_compose.sh",
      "sudo /subspace/setup_rpc_compose.sh 3 0",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}
