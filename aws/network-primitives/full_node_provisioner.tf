locals {
  full_node_ip_v4 = flatten([
    [aws_instance.full_node.*.public_ip]
    ]
  )
}

resource "null_resource" "setup-full-nodes" {
  count = length(local.full_node_ip_v4)

  depends_on = [aws_instance.full_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.full_node_ip_v4)
  }

  connection {
    host        = local.full_node_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/subspace",
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "~/subspace/install_docker.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/subspace/install_docker.sh",
      "sudo ~/subspace/install_docker.sh",
    ]
  }

}

resource "null_resource" "prune-full-nodes" {
  count      = var.full-node-config.prune ? length(local.full_node_ip_v4) : 0
  depends_on = [null_resource.setup-full-nodes]

  triggers = {
    prune = var.full-node-config.prune
  }

  connection {
    host        = local.full_node_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/prune_docker_system.sh"
    destination = "~/subspace/prune_docker_system.sh"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/subspace/prune_docker_system.sh",
      "sudo bash ~/subspace/prune_docker_system.sh"
    ]
  }
}

resource "null_resource" "start-full-nodes" {
  count = length(local.full_node_ip_v4)

  depends_on = [null_resource.setup-full-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.full-node-config.deployment-version
    reserved_only      = var.full-node-config.reserved-only
  }

  connection {
    host        = local.full_node_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # copy node keys file
  provisioner "file" {
    source      = "./full_node_keys.txt"
    destination = "~/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "~/subspace/bootstrap_node_keys.txt"
  }

  # copy DSN bootstrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "~/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_full_node_compose_file.sh"
    destination = "~/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "sudo docker compose -f ~/subspace/docker-compose.yml down ",
      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-full-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.full-node-config.docker-org} > ~/subspace/.env",
      "echo NODE_TAG=${var.full-node-config.docker-tag} >> ~/subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> ~/subspace/.env",
      "echo NODE_ID=${count.index} >> ~/subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' ~/subspace/node_keys.txt) >> ~/subspace/.env",
      "echo DATADOG_API_KEY=${var.datadog_api_key} >> ~/subspace/.env",
      "echo PIECE_CACHE_SIZE=${var.piece_cache_size} >> ~/subspace/.env",
      "echo NODE_DSN_PORT=${var.full-node-config.node-dsn-port} >> ~/subspace/.env",

      # create docker compose file
      "chmod +x ~/subspace/create_compose_file.sh",
      "bash ~/subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.full_node_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)}",

      # start subspace node
      "sudo docker compose -f ~/subspace/docker-compose.yml up -d",
    ]
  }
}
