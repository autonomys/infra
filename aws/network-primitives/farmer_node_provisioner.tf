locals {
  farmer_node_ipv4 = flatten([
    [var.farmer-node-config.additional-node-ips],
    [aws_instance.farmer_node.*.public_ip]
    ]
  )
}

resource "null_resource" "farmer-node-keys" {
  count = length(local.farmer_node_ipv4) > 0 ? 1 : 0

  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", local.farmer_node_ipv4)
  }

  # generate node keys
  provisioner "local-exec" {
    command     = "${var.path_to_scripts}/generate_node_keys.sh ${length(local.farmer_node_ipv4)} ./farmer_node_keys.txt"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      NODE_PUBLIC_IPS = join(",", local.farmer_node_ipv4)
    }
  }
}

resource "null_resource" "setup-farmer-nodes" {
  count = length(local.farmer_node_ipv4)

  depends_on = [null_resource.farmer-node-keys, null_resource.start-boostrap-nodes]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.farmer_node_ipv4)
  }

  connection {
    host           = local.farmer_node_ipv4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    timeout        = "30s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /subspace"
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

resource "null_resource" "prune-farmer-nodes" {
  count      = var.farmer-node-config.prune ? length(local.farmer_node_ipv4) : 0
  depends_on = [null_resource.setup-farmer-nodes]

  triggers = {
    prune = var.farmer-node-config.prune
  }

  connection {
    host           = local.farmer_node_ipv4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    timeout        = "30s"
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

resource "null_resource" "start-farmer-nodes" {
  count = length(local.farmer_node_ipv4)

  depends_on = [null_resource.setup-farmer-nodes, null_resource.boostrap-node-keys]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.farmer-node-config.deployment-version
    reserved_only      = var.farmer-node-config.reserved-only
  }

  connection {
    host           = local.farmer_node_ipv4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    timeout        = "30s"
  }

  # copy node keys file
  provisioner "file" {
    source      = "./farmer_node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/subspace/bootstrap_node_keys.txt"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_farmer_node_compose_file.sh"
    destination = "/subspace/create_compose_file.sh"
  }

  # copy subspace entry script
  provisioner "file" {
    source      = "${var.path_to_scripts}/subspace.sh"
    destination = "/usr/bin/subspace"
  }

  # copy subspace systemd file
  provisioner "file" {
    source      = "${var.path_to_scripts}/subspace.service"
    destination = "/etc/systemd/system/subspace.service"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "systemctl daemon-reload",
      "systemctl stop subspace.service",
      "systemctl reenable subspace.service",

      # set hostname
      "hostnamectl set-hostname ${var.network_name}-farmer-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.farmer-node-config.docker-org} > /subspace/.env",
      "echo NODE_TAG=${var.farmer-node-config.docker-tag} >> /subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "echo DATADOG_API_KEY=${var.datadog_api_key} >> /subspace/.env",
      "echo REWARD_ADDRESS=${var.farmer-node-config.reward-address} >> /subspace/.env",
      "echo PLOT_SIZE=${var.farmer-node-config.plot-size} >> /subspace/.env",
      "echo PIECE_CACHE_SIZE=${var.piece_cache_size} >> /subspace/.env",
      "echo NODE_DSN_PORT=${var.farmer-node-config.node-dsn-port} >> /subspace/.env",

      # create docker compose file
      "sudo chmod +x /subspace/create_compose_file.sh",
      "sudo chmod +x /usr/bin/subspace",
      "sudo /subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.farmer_node_ipv4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)} ${var.farmer-node-config.force-block-production}",

      # start subspace node
      "systemctl start subspace.service",
    ]
  }
}
