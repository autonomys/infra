locals {
  explorer_squid_node_ip_v4 = flatten([
    [digitalocean_droplet.explorer-nodes.*.ipv4_address],
    ]
  )
}


resource "null_resource" "setup-explorer-nodes" {
  count = length(local.explorer_squid_node_ip_v4)

  depends_on = [cloudflare_record.explorer]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.explorer_squid_node_ip_v4)
  }

  connection {
    host           = local.explorer_squid_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "60s"
  }

  # create explorer dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /explorer_squid"
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path-to-scripts}/install_docker.sh"
    destination = "/explorer_squid/install_docker.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /explorer_squid/install_docker.sh",
      "sudo bash /explorer_squid/install_docker.sh",
    ]
  }

}

resource "null_resource" "prune-explorer-nodes" {
  count      = var.explorer-node-config.prune ? length(local.explorer_squid_node_ip_v4) : 0
  depends_on = [null_resource.setup-explorer-nodes]

  triggers = {
    prune = var.explorer-node-config.prune
  }

  connection {
    host           = local.explorer_squid_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "60s"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "docker ps -aq | xargs docker stop",
      "docker system prune -a -f && docker volume ls -q | xargs docker volume rm -f",
    ]
  }
}

resource "null_resource" "start-explorer-nodes" {
  count = length(local.explorer_squid_node_ip_v4)

  depends_on = [null_resource.setup-explorer-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.explorer-node-config.deployment-color
  }

  connection {
    host           = local.explorer_squid_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "60s"
  }

  provisioner "file" {
    source      = "${var.path-to-configs}/nginx-explorer.conf"
    destination = "/etc/nginx/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path-to-configs}/cors-settings.conf"
    destination = "/etc/nginx/cors-settings.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path-to-scripts}/create_explorer_squid_node_compose_file.sh"
    destination = "/explorer_squid/create_compose_file.sh"
  }

  # copy .env file
  provisioner "file" {
    source      = "${var.path-to-scripts}/set_env_vars.sh"
    destination = "/explorer_squid/set_env_vars.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "systemctl daemon-reload",
      "systemctl enable nginx",
      "systemctl start nginx",
      "systemctl stop docker.service",

      # set hostname
      "hostnamectl set-hostname ${var.network-name}-explorer_squid-node-${count.index}",

      # create .env file
      "sudo chmod +x /explorer_squid/set_env_vars.sh",
      "sudo bash /explorer_squid/set_env_vars.sh",

      # create docker compose file
      "sudo chmod +x /explorer_squid/create_compose_file.sh",
      "sudo bash /explorer_squid/create_compose_file.sh",

      # start docker daemon
      "systemctl enable --now docker.service",
      "systemctl stop docker.service",
      "systemctl restart docker.service",
      "sudo docker compose -f /explorer_squid/docker-compose.yml -d",
    ]
  }
}