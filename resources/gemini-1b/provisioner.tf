resource "null_resource" "node_keys" {
  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", digitalocean_droplet.gemini-1b.*.ipv4_address)
  }

  # generate node keys
  provisioner "local-exec" {
    command = "utils/scripts/generate_node_keys.sh ${length(digitalocean_droplet.gemini-1b)} ./node_keys.txt"
    interpreter = [ "/bin/bash", "-c" ]
    environment = {
      NODE_PUBLIC_IPS = join(",", digitalocean_droplet.gemini-1b.*.ipv4_address)
    }
  }
}

resource "null_resource" "setup_nodes" {
  count = length(digitalocean_droplet.gemini-1b)

  depends_on = [null_resource.node_keys, cloudflare_record.bootstrap, cloudflare_record.rpc]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", digitalocean_droplet.gemini-1b.*.ipv4_address)
  }

  connection {
    host = digitalocean_droplet.gemini-1b[count.index].ipv4_address
    user = "root"
    type = "ssh"
    agent = false
#    agent_identity = var.ssh_identity
    private_key = var.alexey2_do_private_key
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
    source = "utils/scripts/install_docker.sh"
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
  deployment_version = 9
}

resource "null_resource" "start_nodes" {
  count = length(digitalocean_droplet.gemini-1b)

  depends_on = [null_resource.setup_nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.deployment_version
  }

  connection {
    host = digitalocean_droplet.gemini-1b[count.index].ipv4_address
    user = "root"
    type = "ssh"
    agent = false
    #    agent_identity = var.ssh_identity
    private_key = var.alexey2_do_private_key
    timeout = "2m"
  }

  # copy node keys file
  provisioner "file" {
    source = "./node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy compose file
  provisioner "file" {
    source = "utils/services/gemini-1/install_compose_file.sh"
    destination = "/subspace/install_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "docker compose -f /subspace/docker-compose.yml down",
      "echo NODE_SNAPSHOT_TAG=${var.node-snapshot-tag} > /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "sudo chmod +x /subspace/install_compose_file.sh",
      "sudo /subspace/install_compose_file.sh ${length(digitalocean_droplet.gemini-1b)} ${count.index}",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}
