locals {
  autoid_nodes_ip_v4 = flatten([[aws_instance.autoid_node.*.public_ip]])
  autoid_nodes_ip_v6 = flatten([[aws_instance.autoid_node.*.ipv6_addresses]])
}

resource "null_resource" "setup-autoid-nodes" {
  count = length(local.autoid_nodes_ip_v4)

  depends_on = [aws_instance.autoid_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.autoid_nodes_ip_v4)
  }

  connection {
    host           = local.autoid_nodes_ip_v4[count.index]
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

  # copy LE script
  provisioner "file" {
    source      = "${var.path_to_scripts}/acme.sh"
    destination = "/home/${var.ssh_user}/subspace/acme.sh"
  }

  # install docker and docker compose and LE script
  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/${var.ssh_user}/subspace/installer.sh",
      "bash /home/${var.ssh_user}/subspace/acme.sh",
    ]
  }

}

resource "null_resource" "start-autoid-nodes" {
  count = length(local.autoid_nodes_ip_v4)

  depends_on = [null_resource.setup-autoid-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.auto-id-domain-node-config.deployment-version
  }

  connection {
    host           = local.autoid_nodes_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/bootstrap_node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_autoid_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/bootstrap_node_autoid_keys.txt"
  }

  # copy dsn_boostrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy keystore
  provisioner "file" {
    source      = "./domains"
    destination = "/home/${var.ssh_user}/subspace/domains/"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_domain_node_compose_file.sh"
    destination = "/home/${var.ssh_user}/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down ",

      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-autoid-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.auto-id-domain-node-config.docker-org} > /home/${var.ssh_user}/subspace/.env",
      "echo DOCKER_TAG=${var.auto-id-domain-node-config.docker-tag} >> /home/${var.ssh_user}/subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_PREFIX=${var.auto-id-domain-node-config.domain-prefix} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_ID=${var.auto-id-domain-node-config.domain-id} >> /home/${var.ssh_user}/subspace/.env",
      "echo OPERATOR_ID=${var.auto-id-domain-node-config.operator-id} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_ID=${count.index} >> /home/${var.ssh_user}/subspace/.env",
      "echo NEW_RELIC_API_KEY=${var.new_relic_api_key} >> /home/${var.ssh_user}/subspace/.env",
      "echo FQDN=${data.cloudflare_zone.cloudflare_zone.name} >> /home/${var.ssh_user}/subspace/.env",

      # create docker compose file
      "bash /home/${var.ssh_user}/subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.bootstrap_nodes_ip_v4)} ${length(local.bootstrap_nodes_autoid_ip_v4)} ${var.auto-id-domain-node-config.domain-id}",

      # start subspace node
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",
    ]
  }
}
