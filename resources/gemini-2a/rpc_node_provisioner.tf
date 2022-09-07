locals {
  rpc_node_ip_v4 = var.hetzner_rpc_node_ips
}

resource "null_resource" "rpc-node-keys" {
  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", local.rpc_node_ip_v4)
  }

  # generate rpc node keys
  provisioner "local-exec" {
    command = "../../scripts/generate_node_keys.sh ${length(local.rpc_node_ip_v4)} ./rpc_node_keys.txt"
    interpreter = [ "/bin/bash", "-c" ]
    environment = {
      NODE_PUBLIC_IPS = join(",", local.rpc_node_ip_v4)
    }
  }
}

resource "null_resource" "setup-rpc-nodes" {
  count = length(local.rpc_node_ip_v4)

  depends_on = [null_resource.rpc-node-keys, null_resource.start-boostrap-nodes, cloudflare_record.rpc]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.rpc_node_ip_v4)
  }

  connection {
    host = local.rpc_node_ip_v4[count.index]
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
  rpc_node_deployment_version = 7
}

resource "null_resource" "start-rpc-nodes" {
  count = length(local.rpc_node_ip_v4)

  depends_on = [null_resource.setup-rpc-nodes, null_resource.boostrap-node-keys]

  # trigger on node deployment version change
  triggers = {
    deployment_version = local.rpc_node_deployment_version
  }

  connection {
    host = local.rpc_node_ip_v4[count.index]
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "10s"
  }

  # copy node keys file
  provisioner "file" {
    source = "./rpc_node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source = "./bootstrap_node_keys.txt"
    destination = "/subspace/bootstrap_node_keys.txt"
  }

  # copy compose file
  provisioner "file" {
    source = "../../scripts/gemini-2/create_rpc_node_compose_file.sh"
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
      "sudo /subspace/create_compose_file.sh ${length(local.rpc_node_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)}",
      "docker compose -f /subspace/docker-compose.yml up -d --remove-orphans",
    ]
  }
}
