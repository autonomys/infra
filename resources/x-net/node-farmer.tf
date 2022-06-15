resource "digitalocean_droplet" "x-net-farmer" {
  image  = "ubuntu-20-04-x64"
  name   = "x-net-farmer"
  region = var.droplet-region
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_firewall" "x-net-farmer-firewall" {
  name = "x-net-farmer-firewall"

  droplet_ids = [digitalocean_droplet.x-net-farmer.id]

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

locals {
  farmer_deployment_version = 1
}

resource "null_resource" "start_farmer_node" {
  depends_on = [null_resource.setup_nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.farmer_deployment_version
  }

  connection {
    host = digitalocean_droplet.x-net-farmer.ipv4_address
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
    source = "../../services/x-net/setup_farmer_compose.sh"
    destination = "/subspace/setup_farmer_compose.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "docker compose -f /subspace/docker-compose.yml down",
      "echo NODE_KEY=$(sed -nr 's/NODE_1_KEY=//p' /subspace/node_keys.txt) > /subspace/.env",
      "echo WALLET_ADDRESS=$(sed -nr 's/WALLET_1_ADDRESS=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "sudo chmod +x /subspace/setup_farmer_compose.sh",
      "sudo /subspace/setup_farmer_compose.sh 3 1",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}


