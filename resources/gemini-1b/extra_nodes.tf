resource "digitalocean_droplet" "gemini-1b-extra" {
  count = var.extra-droplets
  image  = "ubuntu-20-04-x64"
  name   = "gemini-1b-node-extra-${count.index}-sgp1"
  region = "sgp1"
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

locals {
  firewall_extra_sets = [
    slice([for droplet in digitalocean_droplet.gemini-1b-extra: droplet.id], 0, 10),
    slice([for droplet in digitalocean_droplet.gemini-1b-extra: droplet.id], 10, 20)
  ]
}

resource "digitalocean_firewall" "gemini-1b-firewall-extra" {
  count = length(local.firewall_extra_sets)
  name = "gemini-1b-firewall-${count.index}-extra"
  droplet_ids = local.firewall_extra_sets[count.index]

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

resource "null_resource" "setup-nodes-extra" {
  count = length(digitalocean_droplet.gemini-1b-extra)

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", digitalocean_droplet.gemini-1b-extra.*.ipv4_address)
  }

  connection {
    host = digitalocean_droplet.gemini-1b-extra[count.index].ipv4_address
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


# deployment version
# increment this to restart node with any changes to env and compose files
locals {
  deployment_version_extra = 6
}

resource "null_resource" "start-nodes-extra" {
  count = length(digitalocean_droplet.gemini-1b-extra)

  depends_on = [null_resource.setup-nodes-extra]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.deployment_version_extra
  }

  connection {
    host = digitalocean_droplet.gemini-1b-extra[count.index].ipv4_address
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "2m"
  }

  # copy compose file
  provisioner "file" {
    source = "../../services/gemini-1/docker-compose-extra.yml"
    destination = "/subspace/docker-compose.yml"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "docker compose -f /subspace/docker-compose.yml down --remove-orphans",
      "echo NODE_SNAPSHOT_TAG=${var.node-snapshot-tag} > /subspace/.env",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}

