locals {
  nova_squid_nodes_ip_v4 = flatten([
    [aws_instance.nova_squid_node.*.public_ip]
    ]
  )
  nova_squid_nodes_ip_v6 = flatten([
    [aws_instance.nova_squid_node.*.ipv6_addresses]
    ]
  )
}

resource "null_resource" "setup-nova-squid-nodes" {
  count = length(local.nova_squid_nodes_ip_v4)

  depends_on = [aws_instance.nova_squid_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.nova_squid_nodes_ip_v4)
  }

  connection {
    host        = local.nova_squid_nodes_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
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

resource "null_resource" "prune-nova-squid-nodes" {
  count      = var.nova-squid-node-config.prune ? length(local.nova_squid_nodes_ip_v4) : 0
  depends_on = [null_resource.setup-nova-squid-nodes]

  triggers = {
    prune = var.nova-squid-node-config.prune
  }

  connection {
    host        = local.nova_squid_nodes_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/prune_docker_system.sh"
    destination = "/home/${var.ssh_user}/subspace/prune_docker_system.sh"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/${var.ssh_user}/subspace/prune_docker_system.sh"
    ]
  }
}

resource "null_resource" "start-nova-squid-nodes" {
  count = length(local.nova_squid_nodes_ip_v4)

  depends_on = [null_resource.setup-nova-squid-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.nova-squid-node-config.deployment-version
    reserved_only      = var.nova-squid-node-config.reserved-only
  }

  connection {
    host        = local.nova_squid_nodes_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # copy node keys file
  provisioner "file" {
    source      = "./nova_squid_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/bootstrap_node_keys.txt"
  }


  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_evm_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/bootstrap_node_evm_keys.txt"
  }

  # copy dsn_boostrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "/home/${var.ssh_user}/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy keystore
  provisioner "file" {
    source      = "./keystore"
    destination = "/home/${var.ssh_user}/subspace/keystore/"
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
      "sudo hostnamectl set-hostname ${var.network_name}-nova-squid-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.nova-squid-node-config.docker-org} > /home/${var.ssh_user}/subspace/.env",
      "echo NODE_TAG=${var.nova-squid-node-config.docker-tag} >> /home/${var.ssh_user}/subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_PREFIX=${var.nova-squid-node-config.domain-prefix} >> /home/${var.ssh_user}/subspace/.env",
      # //todo use a map for domain id and labels
      "echo DOMAIN_LABEL=${var.nova-squid-node-config.domain-labels[0]} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_ID=${var.nova-squid-node-config.domain-id[0]} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_ID=${count.index} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /home/${var.ssh_user}/subspace/node_keys.txt) >> /home/${var.ssh_user}/subspace/.env",
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_DSN_PORT=${var.nova-squid-node-config.node-dsn-port} >> /home/${var.ssh_user}/subspace/.env",
      "echo POT_EXTERNAL_ENTROPY=${var.pot_external_entropy} >> /home/${var.ssh_user}/subspace/.env",

      # create docker compose file
      "bash /home/${var.ssh_user}/subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.nova_squid_nodes_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)} ${length(local.bootstrap_nodes_evm_ip_v4)} ${var.nova-squid-node-config.enable-domains} ${var.nova-squid-node-config.domain-id[0]}",

      # start subspace node
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",
    ]
  }
}
