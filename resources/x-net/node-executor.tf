resource "digitalocean_droplet" "x-net-executor" {
  image  = "ubuntu-20-04-x64"
  name   = "x-net-executor"
  region = var.droplet-region
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_firewall" "x-net-executor-firewall" {
  name = "x-net-executor-firewall"

  droplet_ids = [digitalocean_droplet.x-net-executor.id]

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
  executor_deployment_version = 4
}

resource "null_resource" "start_executor_node" {
  depends_on = [null_resource.setup_nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.executor_deployment_version
  }

  connection {
    host = digitalocean_droplet.x-net-executor.ipv4_address
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
    source = "../../services/x-net/setup_executor_compose.sh"
    destination = "/subspace/setup_executor_compose.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "docker compose -f /subspace/docker-compose.yml down",
      "mkdir -p /subspace/data/node",
      "mkdir -p /subspace/data/executor",
      "mkdir -p /subspace/data/executor/chains/subspace_x_net_1a_execution/keystore/",
      "echo \"$(sed -nr 's/KEYSTORE_FILE_DATA=//p' /subspace/node_keys.txt)\" > /subspace/data/executor/chains/subspace_x_net_1a_execution/keystore/$(sed -nr 's/KEYSTORE_FILE_NAME=//p' /subspace/node_keys.txt)",
      "chown -R nobody:nogroup /subspace/data",
      "chown -R nobody:nogroup /subspace/data/*",
      "echo NODE_KEY=$(sed -nr 's/NODE_2_KEY=//p' /subspace/node_keys.txt) > /subspace/.env",
      "sudo chmod +x /subspace/setup_executor_compose.sh",
      "sudo /subspace/setup_executor_compose.sh 3 2",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}
