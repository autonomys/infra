locals {
  farmer_nodes_ipv4 = flatten([[aws_instance.farmer_node.*.public_ip]])
}

resource "null_resource" "setup-farmer-nodes" {
  count = length(local.farmer_nodes_ipv4)

  depends_on = [aws_instance.farmer_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.farmer_nodes_ipv4)
  }

  connection {
    host           = local.farmer_nodes_ipv4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/${var.ssh_user}/subspace/",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.ssh_user}/subspace/",
      "sudo mkdir -p /subspace_data/node/",
      "sudo mkdir -p /subspace_data/farmer/",
      "sudo chown -R nobody:nogroup /subspace_data",
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/installer.sh"
    destination = "/home/${var.ssh_user}/subspace/installer.sh"
  }

  # copy config files
  provisioner "file" {
    source      = "${var.path_to_configs}/"
    destination = "/home/${var.ssh_user}/subspace/"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/${var.ssh_user}/subspace/installer.sh",
    ]
  }

}

resource "null_resource" "start-farmer-nodes" {
  count = length(local.farmer_nodes_ipv4)

  depends_on = [null_resource.setup-farmer-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.farmer-node-config.deployment-version
  }

  connection {
    host           = local.farmer_nodes_ipv4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # copy node keys file
  provisioner "file" {
    source      = "./farmer_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/bootstrap_node_keys.txt"
  }

  # copy DSN bootstrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_farmer_node_compose_file.sh"
    destination = "/home/${var.ssh_user}/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down ",

      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-farmer-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.farmer-node-config.docker-org} > /home/${var.ssh_user}/subspace/.env",
      "echo DOCKER_TAG=${var.farmer-node-config.docker-tag} >> /home/${var.ssh_user}/subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_ID=${count.index} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /home/${var.ssh_user}/subspace/node_keys.txt) >> /home/${var.ssh_user}/subspace/.env",
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/subspace/.env",
      "echo REWARD_ADDRESS=${var.farmer-node-config.reward-address} >> /home/${var.ssh_user}/subspace/.env",
      "echo PLOT_SIZE=${var.farmer-node-config.plot-size} >> /home/${var.ssh_user}/subspace/.env",
      "echo CACHE_PERCENTAGE=${var.farmer-node-config.cache-percentage} >> /home/${var.ssh_user}/subspace/.env",
      "echo THREAD_POOL_SIZE=${var.farmer-node-config.thread-pool-size} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_DSN_PORT=${var.farmer-node-config.node-dsn-port} >> /home/${var.ssh_user}/subspace/.env",

      # create docker compose file
      "bash /home/${var.ssh_user}/subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.bootstrap_nodes_ip_v4)} ${var.farmer-node-config.force-block-production} ${var.farmer-node-config.faster-sector-plotting} ",

      # start subspace
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",
    ]
  }
}
