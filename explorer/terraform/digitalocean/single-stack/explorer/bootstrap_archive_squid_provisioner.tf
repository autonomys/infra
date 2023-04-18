locals {
  archive_squid_node_ip_v4 = flatten([
    [digitalocean_droplet.archive-squid-node-blue.*.ipv4_address],
    [digitalocean_droplet.archive-squid-node-green.*.ipv4_address],
    ]
  )
}


resource "null_resource" "setup-archive_squid-nodes" {
  count = length(local.archive_squid_node_ip_v4)

  depends_on = [cloudflare_record.archive-squid]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.archive_squid_node_ip_v4)
  }

  connection {
    host           = local.archive_squid_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
  }

  # create archive_squid dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /archive-squid"
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path-to-scripts}/install_docker.sh"
    destination = "/archive-squid/install_docker.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /archive-squid/install_docker.sh",
      "sudo bash /archive-squid/install_docker.sh",
    ]
  }

}

resource "null_resource" "prune-archive_squid-nodes" {
  count      = var.archive_squid-node-config.prune ? length(local.archive_squid_node_ip_v4) : 0
  depends_on = [null_resource.setup-archive_squid-nodes]

  triggers = {
    prune = var.archive_squid-node-config.prune
  }

  connection {
    host           = local.archive_squid_node_ip_v4[count.index]
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

# Install Nginx proxy as docker container
resource "docker_image" "nginx-archive" {
  name = "nginx:stable-alpine3.17-slim"
}
resource "docker_container" "nginx-archive" {
  name  = "nginx-archive"
  image = docker_image.nginx.latest
  ports {
    internal = 80
    external = 80
  }
  volumes {
    container_path = "/etc/nginx/nginx.conf"
    host_path      = "/archive_squid/nginx.conf"
    read_only      = true
  }
}

resource "null_resource" "start-archive_squid-nodes" {
  count = length(local.archive_squid_node_ip_v4)

  depends_on = [null_resource.setup-archive_squid-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.archive_squid-node-config.deployment-color
  }

  connection {
    host           = local.archive_squid_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_identity
    timeout        = "30s"
  }

  # copy nginx configs
  provisioner "file" {
    source      = "${var.path-to-scripts}/nginx_archive-squid.conf"
    destination = "/archive_squid/nginx_conf"
  }

  provisioner "file" {
    source      = "${var.path-to-scripts}/cors-settings.conf"
    destination = "/archive_squid/cors-settings.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path-to-scripts}/create_archive_squid_node_compose_file.sh"
    destination = "/archive_squid/create_compose_file.sh"
  }

  # copy .env file
  provisioner "file" {
    source      = "${var.path-to-scripts}/set_env_vars.sh"
    destination = "/archive_squid/set_env_vars.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      # stop any running service
      "systemctl daemon-reload",
      "systemctl stop docker.service",

      # set hostname
      "hostnamectl set-hostname ${var.network-name}-archive_squid-node-${count.index}",

      # create .env file
      "sudo chmod +x /archive_squid/set_env_vars.sh",
      "sudo bash /archive_squid/set_env_vars.sh",

      # create nginx config files
      "sudo chmod +x /archive-squid/install_nginx_conf.sh",
      "sudo bash /archive-squid//install_nginx_conf.sh",

      # create docker compose file
      "sudo chmod +x /archive_squid/create_compose_file.sh",
      "sudo bash /archive_squid/create_compose_file.sh",

      # start docker daemon
      "systemctl enable --now docker.service",
      "systemctl stop docker.service",
      "systemctl restart docker.service",
    ]
  }
}
