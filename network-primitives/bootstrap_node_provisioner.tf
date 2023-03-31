locals {
  bootstrap_nodes_ip_v4 = flatten([
    [var.bootstrap-node-config.additional-node-ips],
    [digitalocean_droplet.bootstrap-nodes.*.ipv4_address],
    ]
  )
}

resource "null_resource" "boostrap-node-keys" {
  count = length(local.bootstrap_nodes_ip_v4) > 0 ? 1 : 0

  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", local.bootstrap_nodes_ip_v4)
  }

  # generate node keys
  provisioner "local-exec" {
    command     = "${var.path-to-scripts}/generate_node_keys.sh ${length(local.bootstrap_nodes_ip_v4)} ./bootstrap_node_keys.txt"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      NODE_PUBLIC_IPS = join(",", local.bootstrap_nodes_ip_v4)
    }
  }
}

resource "null_resource" "setup-bootstrap-nodes" {
  count = length(local.bootstrap_nodes_ip_v4)

  depends_on = [null_resource.boostrap-node-keys]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.bootstrap_nodes_ip_v4)
  }

  connection {
    host           = local.bootstrap_nodes_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "10s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /subspace"
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path-to-scripts}/install_docker.sh"
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
    host           = local.bootstrap_nodes_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "10s"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "docker ps -aq | xargs docker stop",
      "docker system prune -a -f --volumes",
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
    host           = local.bootstrap_nodes_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "10s"
  }

  # copy node keys file
  provisioner "file" {
    source      = "./bootstrap_node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # copy boostrap node keys file
  provisioner "file" {
    source      = "./dsn_bootstrap_node_keys.txt"
    destination = "/subspace/dsn_bootstrap_node_keys.txt"
  }

  # copy compose creation file
  provisioner "file" {
    source      = "${var.path-to-scripts}/create_bootstrap_node_compose_file.sh"
    destination = "/subspace/create_compose_file.sh"
  }

  # copy subspace entry script
  provisioner "file" {
    source      = "${var.path-to-scripts}/subspace.sh"
    destination = "/usr/bin/subspace"
  }

  # copy subspace systemd file
  provisioner "file" {
    source      = "${var.path-to-scripts}/subspace.service"
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
      "hostnamectl set-hostname ${var.network-name}-bootstrap-node-${count.index}",

      # create .env file
      "echo NODE_ORG=${var.bootstrap-node-config.docker-org} > /subspace/.env",
      "echo NODE_TAG=${var.bootstrap-node-config.docker-tag} >> /subspace/.env",
      "echo NETWORK_NAME=${var.network-name} >> /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "echo DATADOG_API_KEY=${var.datadog_api_key} >> /subspace/.env",
      "echo PIECE_CACHE_SIZE=${var.piece_cache_size} >> /subspace/.env",
      "echo DSN_NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/dsn_bootstrap_node_keys.txt) >> /subspace/.env",

      # create docker compose file
      "sudo chmod +x /subspace/create_compose_file.sh",
      "sudo chmod +x /usr/bin/subspace",
      "sudo /subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.bootstrap_nodes_ip_v4)} ${count.index}",

      # start subspace node
      "systemctl start subspace.service",
    ]
  }
}
