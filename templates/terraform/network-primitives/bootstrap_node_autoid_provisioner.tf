locals {
  bootstrap_nodes_autoid_ip_v4 = flatten([[aws_instance.bootstrap_node_autoid.*.public_ip]])
  bootstrap_nodes_autoid_ip_v6 = flatten([[aws_instance.bootstrap_node_autoid.*.ipv6_addresses]])
}

resource "null_resource" "setup-bootstrap-nodes-autoid" {
  count = length(local.bootstrap_nodes_autoid_ip_v4)

  depends_on = [aws_instance.bootstrap_node_autoid]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.bootstrap_nodes_autoid_ip_v4)
  }

  connection {
    host           = local.bootstrap_nodes_autoid_ip_v4[count.index]
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

resource "null_resource" "start-bootstrap-nodes-autoid" {
  count = length(local.bootstrap_nodes_autoid_ip_v4)

  depends_on = [null_resource.setup-bootstrap-nodes-autoid]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.bootstrap-node-autoid-config.deployment-version
  }

  connection {
    host           = local.bootstrap_nodes_autoid_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # copy bootstrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_autoid_keys.txt"
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
      "sudo hostnamectl set-hostname ${var.network_name}-bootstrap-node-autoid-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.bootstrap-node-autoid-config.docker-org} > /home/${var.ssh_user}/subspace/.env",
      "echo DOCKER_TAG=${var.bootstrap-node-autoid-config.docker-tag} >> /home/${var.ssh_user}/subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_ID=${count.index} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /home/${var.ssh_user}/subspace/node_keys.txt) >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_PREFIX=${var.bootstrap-node-autoid-config.domain-prefix} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_ID=${var.bootstrap-node-autoid-config.domain-id} >> /home/${var.ssh_user}/subspace/.env",
      "echo NEW_RELIC_API_KEY=${var.new_relic_api_key} >> /home/${var.ssh_user}/subspace/.env",

      # create docker compose file
      "bash /home/${var.ssh_user}/subspace/create_compose_file.sh ${var.bootstrap-node-autoid-config.reserved-only} ${length(local.bootstrap_nodes_autoid_ip_v4)} ${length(local.bootstrap_nodes_ip_v4)} ",

      # start subspace node
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",
    ]
  }
}
