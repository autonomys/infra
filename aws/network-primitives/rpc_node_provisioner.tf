locals {
  rpc_node_ip_v4 = flatten([
    #   [var.rpc-node-config.additional-node-ips],
    [aws_instance.rpc_node.*.public_ip]
    ]
  )
}

resource "null_resource" "setup-rpc-nodes" {
  count = length(local.rpc_node_ip_v4)

  depends_on = [aws_instance.rpc_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.rpc_node_ip_v4)
  }

  connection {
    host        = local.rpc_node_ip_v4[count.index]
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
      "sudo mkdir -p /home/ubuntu/bin",
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

resource "null_resource" "prune-rpc-nodes" {
  count      = var.rpc-node-config.prune ? length(local.rpc_node_ip_v4) : 0
  depends_on = [null_resource.setup-rpc-nodes]

  triggers = {
    prune = var.rpc-node-config.prune
  }

  connection {
    host        = local.rpc_node_ip_v4[count.index]
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

resource "null_resource" "start-rpc-nodes" {
  count = length(local.rpc_node_ip_v4)

  depends_on = [null_resource.setup-rpc-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.rpc-node-config.deployment-version
    reserved_only      = var.rpc-node-config.reserved-only
  }

  connection {
    host        = local.rpc_node_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # copy node keys file
  provisioner "file" {
    source      = "./rpc_node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/subspace/bootstrap_node_keys.txt"
  }

  # copy DSN bootstrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy keystore
  provisioner "file" {
    source      = "./keystore"
    destination = "/subspace/keystore/"
  }

  # copy relayer ids
  provisioner "file" {
    source      = "./relayer_ids.txt"
    destination = "/subspace/relayer_ids.txt"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_rpc_node_compose_file.sh"
    destination = "/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "sudo docker compose -f /subspace/docker-compose.yml down ",

      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-rpc-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.rpc-node-config.docker-org} > /subspace/.env",
      "echo NODE_TAG=${var.rpc-node-config.docker-tag} >> /subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /subspace/.env",
      "echo DOMAIN_PREFIX=${var.rpc-node-config.domain-prefix} >> /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "echo DATADOG_API_KEY=${var.datadog_api_key} >> /subspace/.env",
      "echo PIECE_CACHE_SIZE=${var.piece_cache_size} >> /subspace/.env",
      "echo NODE_DSN_PORT=${var.rpc-node-config.node-dsn-port} >> /subspace/.env",

      # create docker compose file
      "sudo chmod +x /subspace/create_compose_file.sh",
      "sudo /subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.rpc_node_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)}",

      # start subspace node
      "sudo chown ubuntu:ubuntu /subspace/docker-compose.yml",
      "sudo docker compose -f /subspace/docker-compose.yml up -d --build ",
    ]
  }
}

resource "null_resource" "inject-keystore" {
  # for now we have one executor running. Should change here when multiple executors are expected.
  count      = length(local.rpc_node_ip_v4) > 0 ? 1 : 0
  depends_on = [null_resource.start-rpc-nodes]
  # trigger on node deployment version change
  triggers = {
    deployment_version = var.rpc-node-config.deployment-version
  }

  connection {
    host        = local.rpc_node_ip_v4[0]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo docker cp /subspace/keystore/.  subspace-archival-node-1:/var/subspace/keystore/"
    ]
  }
}
