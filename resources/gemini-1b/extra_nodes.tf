resource "digitalocean_droplet" "gemini-1b-extra" {
  image  = "ubuntu-20-04-x64"
  name   = "gemini-1b-node-extra-0-sgp1"
  region = "sgp1"
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

resource "digitalocean_firewall" "gemini-1b-firewall-extra" {
  name = "gemini-1b-firewall-extra"

  droplet_ids = [digitalocean_droplet.gemini-1b-extra.id]

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

resource "null_resource" "setup_nodes-extra" {

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4 = digitalocean_droplet.gemini-1b-extra.ipv4_address
  }

  connection {
    host = digitalocean_droplet.gemini-1b-extra.ipv4_address
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "2m"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /subspace"
    ]
  }

  # copy install file
  provisioner "file" {
    source = "../../scripts/install_docker.sh"
    destination = "/subspace/install_docker.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /subspace/install_docker.sh",
      "sudo /subspace/install_docker.sh"
    ]
  }

}

resource "null_resource" "start_nodes_extra" {
  depends_on = [null_resource.setup_nodes-extra]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.deployment_version
  }

  connection {
    host = digitalocean_droplet.gemini-1b-extra.ipv4_address
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
    source = "../../services/gemini-1/install_compose_file.sh"
    destination = "/subspace/install_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "docker compose -f /subspace/docker-compose.yml down",
      "echo NODE_SNAPSHOT_TAG=${var.node-snapshot-tag} >> /subspace/.env",
      "echo NODE_ID=12 >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_12_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "sudo chmod +x /subspace/install_compose_file.sh",
      "sudo /subspace/install_compose_file.sh 13 12",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}

