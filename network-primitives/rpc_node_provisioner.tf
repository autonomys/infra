locals {
  rpc_node_ip_v4 = flatten([
    [var.rpc-node-config.additional-node-ips],
    [digitalocean_droplet.rpc-nodes.*.ipv4_address],
    ]
  )
}

resource "null_resource" "rpc-node-keys" {
  count = length(local.rpc_node_ip_v4) > 0 ? 1 : 0

  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", local.rpc_node_ip_v4)
  }

  # generate rpc node keys
  provisioner "local-exec" {
    command     = "${var.path-to-scripts}/generate_node_keys.sh ${length(local.rpc_node_ip_v4)} ./rpc_node_keys.txt"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      NODE_PUBLIC_IPS = join(",", local.rpc_node_ip_v4)
    }
  }
}

resource "null_resource" "setup-rpc-nodes" {
  count = length(local.rpc_node_ip_v4)

  depends_on = [null_resource.rpc-node-keys, null_resource.start-boostrap-nodes, cloudflare_record.rpc]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.rpc_node_ip_v4)
  }

  connection {
    host           = local.rpc_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
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

resource "null_resource" "prune-rpc-nodes" {
  count      = var.rpc-node-config.prune ? length(local.rpc_node_ip_v4) : 0
  depends_on = [null_resource.setup-rpc-nodes]

  triggers = {
    prune = var.rpc-node-config.prune
  }

  connection {
    host           = local.rpc_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
  }

  provisioner "file" {
    source      = "${var.path-to-scripts}/prune_docker_system.sh"
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

  depends_on = [null_resource.setup-rpc-nodes, null_resource.boostrap-node-keys]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.rpc-node-config.deployment-version
    reserved_only      = var.rpc-node-config.reserved-only
  }

  connection {
    host           = local.rpc_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
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
    source      = "${var.path-to-scripts}/create_rpc_node_compose_file.sh"
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
      "hostnamectl set-hostname ${var.rpc-node-config.domain-prefix}-${count.index}.${var.network-name}-rpc-node",

      # create .env file
      "echo NODE_ORG=${var.rpc-node-config.docker-org} > /subspace/.env",
      "echo NODE_TAG=${var.rpc-node-config.docker-tag} >> /subspace/.env",
      "echo NETWORK_NAME=${var.network-name} >> /subspace/.env",
      "echo DOMAIN_PREFIX=${var.rpc-node-config.domain-prefix} >> /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "echo RELAYER_SYSTEM_ID=$(sed -nr 's/NODE_${count.index}=//p' /subspace/relayer_ids.txt) >> /subspace/.env",
      "echo DATADOG_API_KEY=${var.datadog_api_key} >> /subspace/.env",
      "echo PIECE_CACHE_SIZE=${var.piece_cache_size} >> /subspace/.env",
      "echo NODE_DSN_PORT=${var.rpc-node-config.node-dsn-port} >> /subspace/.env",

      # create docker compose file
      "sudo chmod +x /subspace/create_compose_file.sh",
      "sudo chmod +x /usr/bin/subspace",
      "sudo /subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.rpc_node_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)} ${var.rpc-node-config.enable-domains}",

      # start subspace node
      "systemctl start subspace.service",
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
    host           = local.rpc_node_ip_v4[0]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "docker cp /subspace/keystore/.  subspace-archival-node-1:/var/subspace/keystore/"
    ]
  }
}
