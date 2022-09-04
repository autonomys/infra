resource "digitalocean_droplet" "gemini-2a-bootstrap-nodes" {
  count = length(var.bootstrap-node-regions) * var.bootstrap-nodes-per-region
  image  = "ubuntu-22-04-x64"
  name   = "gemini-2a-bootstrap-node-${count.index}-${var.bootstrap-node-regions[count.index % length(var.bootstrap-node-regions)]}"
  region = var.bootstrap-node-regions[count.index % length(var.bootstrap-node-regions)]
  size   = var.droplet-size
  ssh_keys = local.ssh_keys
}

resource "null_resource" "boostrap-node-keys" {
  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", digitalocean_droplet.gemini-2a-bootstrap-nodes.*.ipv4_address)
  }

  # generate rpc node keys
  provisioner "local-exec" {
    command = "../../scripts/generate_node_keys.sh ${length(digitalocean_droplet.gemini-2a-bootstrap-nodes)} ./bootstrap_node_keys.txt"
    interpreter = [ "/bin/bash", "-c" ]
    environment = {
      NODE_PUBLIC_IPS = join(",", digitalocean_droplet.gemini-2a-bootstrap-nodes.*.ipv4_address)
    }
  }
}

resource "null_resource" "setup-bootstrap-nodes" {
  count = length(digitalocean_droplet.gemini-2a-bootstrap-nodes)

  depends_on = [null_resource.boostrap-node-keys]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", digitalocean_droplet.gemini-2a-bootstrap-nodes.*.ipv4_address)
  }

  connection {
    host = digitalocean_droplet.gemini-2a-bootstrap-nodes[count.index].ipv4_address
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "10s"
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
  boostrap_node_deployment_version = 1
}

resource "null_resource" "start-boostrap-nodes" {
  count = length(digitalocean_droplet.gemini-2a-bootstrap-nodes)

  depends_on = [null_resource.setup-bootstrap-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.boostrap_node_deployment_version
  }

  connection {
    host = digitalocean_droplet.gemini-2a-bootstrap-nodes[count.index].ipv4_address
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "10s"
  }

  # copy node keys file
  provisioner "file" {
    source = "./bootstrap_node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy compose file
  provisioner "file" {
    source = "../../services/gemini-2/create_bootstrap_node_compose_file.sh"
    destination = "/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "docker compose -f /subspace/docker-compose.yml down",
      "echo NODE_SNAPSHOT_TAG=${var.node-snapshot-tag} > /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "sudo chmod +x /subspace/create_compose_file.sh",
      "sudo /subspace/create_compose_file.sh ${length(digitalocean_droplet.gemini-2a-bootstrap-nodes)} ${count.index}",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}
