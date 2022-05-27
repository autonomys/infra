resource "digitalocean_droplet" "gemini-1a-temp" {
  image  = "ubuntu-20-04-x64"
  name   = "gemini-1a-temp-node"
  region = "ams3"
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}


resource "cloudflare_record" "gemini-1a" {
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "gemini-1a"
  value   = digitalocean_droplet.gemini-1a-temp.ipv4_address
  type    = "A"
}

resource "null_resource" "node_keys_temp" {
  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    temp_ipv4 = digitalocean_droplet.gemini-1a-temp.ipv4_address
  }

  # generate node keys
  provisioner "local-exec" {
    command = "../../scripts/generate_node_keys.sh 1 ./node_keys_temp.txt"
    interpreter = [ "/bin/bash", "-c" ]
    environment = {
      NODE_PUBLIC_IPS = digitalocean_droplet.gemini-1a-temp.ipv4_address
    }
  }
}

resource "null_resource" "setup_nodes_temp" {
  depends_on = [null_resource.node_keys_temp, cloudflare_record.gemini-1a]

  # trigger on node ip changes
  triggers = {
    temp_ipv4 = digitalocean_droplet.gemini-1a-temp.ipv4_address
  }

  connection {
    host = digitalocean_droplet.gemini-1a-temp.ipv4_address
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
  deployment_version_temp = 1
}

resource "null_resource" "start_temp_nodes" {
  depends_on = [null_resource.setup_nodes_temp]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.deployment_version_temp
  }

  connection {
    host = digitalocean_droplet.gemini-1a-temp.ipv4_address
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "2m"
  }

  # copy node keys file
  provisioner "file" {
    source = "./node_keys_temp.txt"
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
      "echo NODE_SNAPSHOT_TAG=${var.node-snapshot-tag} >> /subspace/.env",
      "echo NODE_ID=0 >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_0_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "sudo chmod +x /subspace/install_compose_file.sh",
      "sudo /subspace/install_compose_file.sh 1 0",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}
