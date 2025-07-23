locals {
  bootstrap_nodes_evm_ip_v4 = flatten([[aws_instance.bootstrap_node_evm.*.public_ip]])
  bootstrap_nodes_evm_ip_v6 = flatten([[aws_instance.bootstrap_node_evm.*.ipv6_addresses]])
}

resource "null_resource" "setup-bootstrap-nodes-evm" {
  count = length(local.bootstrap_nodes_evm_ip_v4)

  depends_on = [aws_instance.bootstrap_node_evm]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.bootstrap_nodes_evm_ip_v4)
  }

  connection {
    host           = local.bootstrap_nodes_evm_ip_v4[count.index]
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
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.ssh_user}/subspace/"
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

resource "null_resource" "start-bootstrap-nodes-evm" {
  count = length(local.bootstrap_nodes_evm_ip_v4)

  depends_on = [null_resource.setup-bootstrap-nodes-evm]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.bootstrap-node-evm-config.deployment-version
  }

  connection {
    host           = local.bootstrap_nodes_evm_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # copy bootstrap evm node keys file
  provisioner "file" {
    source      = "./bootstrap_node_evm_keys.txt"
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
    source      = "${var.path_to_scripts}/create_bootstrap_node_domain_compose_file.sh"
    destination = "/home/${var.ssh_user}/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down ",

      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-bootstrap-node-evm-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.bootstrap-node-evm-config.docker-org} > /home/${var.ssh_user}/subspace/.env",
      "echo DOCKER_TAG=${var.bootstrap-node-evm-config.docker-tag} >> /home/${var.ssh_user}/subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_ID=${count.index} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /home/${var.ssh_user}/subspace/node_keys.txt) >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_LABEL=${var.auto-evm-domain-node-config.domain-labels[0]} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_ID=${var.auto-evm-domain-node-config.domain-id} >> /home/${var.ssh_user}/subspace/.env",
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/subspace/.env",
      "echo DSN_NODE_ID=${count.index} >> /home/${var.ssh_user}/subspace/.env",
      "echo DSN_NODE_KEY=$(sed -nr 's/NODE_${count.index}_DSN_KEY=//p' /home/${var.ssh_user}/subspace/node_keys.txt) >> /home/${var.ssh_user}/subspace/.env",
      "echo DSN_LISTEN_PORT=${var.bootstrap-node-evm-config.dsn-listen-port} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_DSN_PORT=${var.bootstrap-node-evm-config.node-dsn-port} >> /home/${var.ssh_user}/subspace/.env",
      "echo OPERATOR_PORT=${var.bootstrap-node-evm-config.operator-port} >> /home/${var.ssh_user}/subspace/.env",
      "echo GENESIS_HASH=${var.bootstrap-node-evm-config.genesis-hash} >> /home/${var.ssh_user}/subspace/.env",

      # create docker compose file
      "bash /home/${var.ssh_user}/subspace/create_compose_file.sh ${var.bootstrap-node-evm-config.reserved-only} ${length(local.bootstrap_nodes_evm_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)} ",

      # start subspace node
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",
    ]
  }
}
