locals {
  squid_node_ip_v4 = flatten([
    [aws_instance.squid_blue_node.*.public_ip],
    [aws_instance.squid_green_node.*.public_ip],
    ]
  )
}


resource "null_resource" "setup-squid-nodes" {
  count = length(local.squid_node_ip_v4)

  depends_on = [aws_instance.archive_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.squid_node_ip_v4)
  }

  connection {
    host           = local.squid_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"
  }

  # create squid dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /archive",
      "sudo chown ubuntu:ubuntu /archive",
      "sudo chmod -R 770 /archive",
      "sudo mkdir -p /squid/postgresql/data",
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path_to_configs}/postgresql.conf"
    destination = "/squid/postgresql/postgresql.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_squid_node_compose_file.sh"
    destination = "/squid/create_compose_file.sh"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/set_env_vars.sh"
    destination = "/squid/set_env_vars.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/squid/install_docker.sh"
  }

}

resource "null_resource" "prune-squid-nodes" {
  count      = var.squid-node-config.prune ? length(local.squid_node_ip_v4) : 0
  depends_on = [null_resource.setup-squid-nodes]

  triggers = {
    prune = var.squid-node-config.prune
  }

  connection {
    host           = local.squid_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "sudo docker ps -aq | xargs docker stop",
      "sudo docker system prune -a -f && docker volume ls -q | xargs docker volume rm -f",
    ]
  }
}

resource "null_resource" "start-squid-nodes" {
  count = length(local.squid_node_ip_v4)

  depends_on = [null_resource.setup-squid-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.squid-node-config.deployment-color
  }

  connection {
    host           = local.squid_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"

  }

  # install nginx, certbot, docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /squid/install_docker.sh",
      "sudo bash /squid/install_docker.sh",
      "sudo DEBIAN_FRONTEND=noninteractive apt install nginx certbot python3-certbot-nginx --no-install-recommends -y",
    ]
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/nginx-squid.conf"
    destination = "/etc/nginx/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/cors-settings.conf"
    destination = "/etc/nginx/cors-settings.conf"
  }
  # copy nginx install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_nginx.sh"
    destination = "/squid/install_nginx.sh"
  }

  # install deployments
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /squid/install_nginx.sh",
      "sudo bash /squid/install_nginx.sh",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot certonly --dry-run --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.squid-node-config.domain-prefix}.${var.squid-node-config.network-name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname ${var.squid-node-config.domain-prefix}-${var.squid-node-config.network-name}",
      # create .env file
      "sudo chmod +x /squid/set_env_vars.sh",
      "sudo bash /squid/set_env_vars.sh",
      "source ~/.bash_profile",
      # create docker compose file
      "sudo chmod +x /squid/create_compose_file.sh",
      "sudo bash /squid/create_compose_file.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl stop docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f /squid/docker-compose.yml up -d",
      "echo 'Installation Complete'",
    ]
  }

}
