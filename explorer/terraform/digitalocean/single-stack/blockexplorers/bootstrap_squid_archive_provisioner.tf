locals {
  squid_archive_node_ip_v4 = flatten([
    [digitalocean_droplet.squid-archive-node-blue.*.ipv4_address],
    [digitalocean_droplet.squid-archive-node-green.*.ipv4_address],
    ]
  )
}


resource "null_resource" "setup-squid_archive-nodes" {
  count = length(local.squid_archive_node_ip_v4)

  depends_on = [cloudflare_record.squid-archive]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.squid_archive_node_ip_v4)
  }

  connection {
    host           = local.squid_archive_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
  }

  # create squid_archive dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /squid-archive"
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path-to-scripts}/install_docker.sh"
    destination = "/squid-archive/install_docker.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /squid-archive/install_docker.sh",
      "sudo /squid-archive/install_docker.sh",
    ]
  }

}

resource "null_resource" "prune-squid_archive-nodes" {
  count      = var.squid_archive-node-config.prune ? length(local.squid_archive_node_ip_v4) : 0
  depends_on = [null_resource.setup-squid_archive-nodes]

  triggers = {
    prune = var.squid_archive-node-config.prune
  }

  connection {
    host           = local.squid_archive_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "docker ps -aq | xargs docker stop",
      "docker system prune -a -f && docker volume ls -q | xargs docker volume rm -f",
    ]
  }
}


resource "null_resource" "start-squid_archive-nodes" {
  count = length(local.squid_archive_node_ip_v4)

  depends_on = [null_resource.setup-squid_archive-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.squid_archive-node-config.deployment-color
  }

  connection {
    host           = local.squid_archive_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
  }


  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path-to-scripts}/create_squid_archive_node_compose_file.sh"
    destination = "/subspace/create_compose_file.sh"
  }

  # copy .env file
  provisioner "file" {
    source      = "${var.path-to-scripts}/env.sh"
    destination = "/subspace/env.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "systemctl daemon-reload",
      "systemctl enable --now nginx.service",
      "systemctl restart nginx.service",

      # set hostname
      "hostnamectl set-hostname ${var.network-name}-squid_archive-node-${count.index}",

      # create .env file
      "sudo chmod +x /subspace/set_env_vars.sh",
      "sudo bash /subspace/set_env_vars.sh",

      # create docker compose file
      "sudo chmod +x /subspace/create_compose_file.sh",
      "sudo chmod +x /usr/bin/subspace",
      "sudo /subspace/create_compose_file.sh ${var.bootstrap-node-config.reserved-only} ${length(local.squid_archive_node_ip_v4)} ${count.index} ${length(local.bootstrap_nodes_ip_v4)}",

      # start docker daemon
      "systemctl start docker.service",
      "systemctl enable --now docker.service",
      "systemctl restart docker.service",
    ]
  }
}
