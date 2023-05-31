locals {
  bootstrap_nodes_ip_v4 = flatten([
    #   [var.bootstrap-node-config.additional-node-ips],
    [aws_instance.bootstrap_node.*.public_ip]
    ]
  )
}

resource "null_resource" "setup-bootstrap-nodes" {
  count = length(local.bootstrap_nodes_ip_v4)

  depends_on = [aws_instance.bootstrap_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.bootstrap_nodes_ip_v4)
  }

  connection {
    host        = local.bootstrap_nodes_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /subspace",
      "sudo mkdir -p /home/ubuntu/bin/",
      "sudo chown ubuntu:ubuntu /subspace && sudo chmod -R 770 /subspace",
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/subspace/install_docker.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /subspace/install_docker.sh",
      "sudo /subspace/install_docker.sh",
    ]
  }

}

resource "null_resource" "prune-bootstrap-nodes" {
  count      = var.bootstrap-node-config.prune ? length(local.bootstrap_nodes_ip_v4) : 0
  depends_on = [null_resource.setup-bootstrap-nodes]

  triggers = {
    prune = var.bootstrap-node-config.prune
  }

  connection {
    host        = local.bootstrap_nodes_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/prune_docker_system.sh"
    destination = "/tmp/prune_docker_system.sh"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/prune_docker_system.sh",
      "sudo /tmp/prune_docker_system.sh"
    ]
  }
}

resource "null_resource" "start-boostrap-nodes" {
  count = length(local.bootstrap_nodes_ip_v4)

  depends_on = [null_resource.setup-bootstrap-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.bootstrap-node-config.deployment-version
    reserved_only      = var.bootstrap-node-config.reserved-only
  }

  connection {
    host        = local.bootstrap_nodes_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # copy bootstrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy DSN bootstrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_bootstrap_node_compose_file.sh"
    destination = "/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "sudo docker compose -f /subspace/docker-compose.yml down ",

      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-bootstrap-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.bootstrap-node-config.docker-org} > /subspace/.env",
      "echo NODE_TAG=${var.bootstrap-node-config.docker-tag} >> /subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "echo DATADOG_API_KEY=${var.datadog_api_key} >> /subspace/.env",
      "echo PIECE_CACHE_SIZE=${var.piece_cache_size} >> /subspace/.env",
      "echo DSN_NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/dsn_bootstrap_node_keys.txt) >> /subspace/.env",
      "echo DSN_LISTEN_PORT=${var.bootstrap-node-config.dsn-listen-port} >> /subspace/.env",
      "echo NODE_DSN_PORT=${var.bootstrap-node-config.node-dsn-port} >> /subspace/.env",
      "echo GENESIS_HASH=${var.bootstrap-node-config.genesis-hash} >> /subspace/.env",

      # create docker compose file
      "sudo chmod +x /subspace/create_compose_file.sh",
      "sudo /subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.bootstrap_nodes_ip_v4)} ${count.index}",

      # start subspace node
      "sudo chown ubuntu:ubuntu /subspace/docker-compose.yml",
      "sudo docker compose -f /subspace/docker-compose.yml up -d --build ",
    ]
  }
}
