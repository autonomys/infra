locals {
  domain_node_ip_v4 = flatten([
    [var.domain-node-config.additional-node-ips]
    ]
  )
}

resource "null_resource" "setup-domain-nodes" {
  count = length(local.domain_node_ip_v4)

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.domain_node_ip_v4)
  }

  connection {
    host        = local.domain_node_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /root/subspace/",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /root/subspace/ && sudo chmod -R 750 /root/subspace/"
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/installer.sh"
    destination = "/root/subspace/installer.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo bash /root/subspace/installer.sh",
    ]
  }
}

resource "null_resource" "clone_branch" {
  count = var.branch_name != "main" ? 1 : 0

  provisioner "remote-exec" {
    inline = [
      "cd /root/subspace/",
      "git clone https://github.com/autonomys/subspace.git",
      "cd subspace",
      "git checkout ${var.branch_name}"
    ]
  }
}

resource "null_resource" "prune-domain-nodes" {
  count      = var.domain-node-config.prune ? length(local.domain_node_ip_v4) : 0
  depends_on = [null_resource.setup-domain-nodes]

  triggers = {
    prune = var.domain-node-config.prune
  }

  connection {
    host        = local.domain_node_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/prune_docker_system.sh"
    destination = "/root/subspace/prune_docker_system.sh"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "sudo bash /root/subspace/prune_docker_system.sh"
    ]
  }
}

resource "null_resource" "start-domain-nodes" {
  count = length(local.domain_node_ip_v4)

  depends_on = [null_resource.setup-domain-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.domain-node-config.deployment-version
    reserved_only      = var.domain-node-config.reserved-only
  }

  connection {
    host        = local.domain_node_ip_v4[count.index]
    user        = var.ssh_user
    type        = "ssh"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

  # copy node keys file
  provisioner "file" {
    source      = "./domain_node_keys.txt"
    destination = "/root/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/root/subspace/bootstrap_node_keys.txt"
  }

  # copy dsn_boostrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "/root/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy keystore
  provisioner "file" {
    source      = "./keystore"
    destination = "/root/subspace/keystore/"
  }

  # copy relayer ids
  provisioner "file" {
    source      = "./relayer_ids.txt"
    destination = "/root/subspace/relayer_ids.txt"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_domain_node_compose_file.sh"
    destination = "/root/subspace/create_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "sudo docker compose -f /root/subspace/subspace/docker-compose.yml down ",

      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-domain-node-${count.index}",

      # create .env file
      "echo REPO_ORG=${var.domain-node-config.repo-org} > /root/subspace/.env",
      "echo DOCKER_TAG=${var.domain-node-config.docker-tag} >> /root/subspace/.env",
      "echo NETWORK_NAME=${var.network_name} >> /root/subspace/.env",
      "echo DOMAIN_PREFIX=${var.domain-node-config.domain-prefix[0]} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_LABEL=${var.domain-node-config.domain-labels[0]} >> /home/${var.ssh_user}/subspace/.env",
      "echo DOMAIN_ID=${var.domain-node-config.domain-id[0]} >> /home/${var.ssh_user}/subspace/.env",
      "echo NODE_ID=${count.index} >> /root/subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /root/subspace/node_keys.txt) >> /root/subspace/.env",
      "echo PIECE_CACHE_SIZE=${var.piece_cache_size} >> /root/subspace/.env",
      "echo NODE_DSN_PORT=${var.domain-node-config.node-dsn-port} >> /root/subspace/.env",
      "echo BRANCH_NAME=${var.branch_name} >> /root/subspace/.env",

      # create docker compose file
      "bash /root/subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.domain_node_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)} ${var.domain-node-config.enable-domains} ${var.domain-node-config.domain-id[0]}",

      # start subspace node
      var.branch_name != "main" ? join(" && ", [
        "cp -f /root/subspace/.env /root/subspace/subspace/.env",
        "sudo docker compose -f /root/subspace/subspace/docker-compose.yml up -d"
      ]) : "sudo docker compose -f /root/subspace/docker-compose.yml up -d"
    ]
  }
}
