locals {
  blue_squid_node_ip_v4 = flatten([
    [aws_instance.squid_blue_node.*.public_ip],
    ]
  )

  green_squid_node_ip_v4 = flatten([
    [aws_instance.squid_green_node.*.public_ip],
    ]
  )
}


resource "null_resource" "setup-blue-squid-nodes" {
  count = length(local.blue_squid_node_ip_v4)

  depends_on = [aws_instance.archive_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.blue_squid_node_ip_v4)
  }

  connection {
    host           = local.blue_squid_node_ip_v4[count.index]
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
      "sudo mkdir -p /home/${var.ssh_user}/squid",
      "sudo mkdir -p /home/${var.ssh_user}/squid/postgresql",
      "sudo mkdir -p /home/${var.ssh_user}/squid/postgresql/{conf,data}",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/squid/ && sudo chmod -R 755 /home/${var.ssh_user}/squid/"
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path_to_configs}/postgresql.conf"
    destination = "/home/${var.ssh_user}/squid/postgresql/conf/postgresql.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_squid_node_compose_file.sh"
    destination = "/home/${var.ssh_user}/squid/create_compose_file.sh"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/set_env_vars.sh"
    destination = "/home/${var.ssh_user}/squid/set_env_vars.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/squid/install_docker.sh"
  }

}

resource "null_resource" "setup-green-squid-nodes" {
  count = length(local.green_squid_node_ip_v4)

  depends_on = [aws_instance.archive_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.green_squid_node_ip_v4)
  }

  connection {
    host           = local.green_squid_node_ip_v4[count.index]
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
      "mkdir -p /home/${var.ssh_user}/squid",
      "mkdir -p /home/${var.ssh_user}/squid/postgresql",
      "mkdir -p /home/${var.ssh_user}/squid/postgresql/{conf,data}",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/squid/ && sudo chmod -R 755 /home/${var.ssh_user}/squid/"
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path_to_configs}/postgresql.conf"
    destination = "/home/${var.ssh_user}/squid/postgresql/conf/postgresql.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_squid_node_compose_file.sh"
    destination = "/home/${var.ssh_user}/squid/create_compose_file.sh"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/set_env_vars.sh"
    destination = "/home/${var.ssh_user}/squid/set_env_vars.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/squid/install_docker.sh"
  }

}


resource "null_resource" "prune-blue-squid-nodes" {
  count      = var.blue-squid-node-config.prune ? length(local.blue_squid_node_ip_v4) : 0
  depends_on = [null_resource.setup-blue-squid-nodes]

  triggers = {
    prune = var.blue-squid-node-config.prune
  }

  connection {
    host           = local.blue_squid_node_ip_v4[count.index]
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
      "cat /dev/null > $HOME/.bash_profile"
    ]
  }
}

resource "null_resource" "prune-green-squid-nodes" {
  count      = var.green-squid-node-config.prune ? length(local.green_squid_node_ip_v4) : 0
  depends_on = [null_resource.setup-green-squid-nodes]

  triggers = {
    prune = var.green-squid-node-config.prune
  }

  connection {
    host           = local.green_squid_node_ip_v4[count.index]
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
      "cat /dev/null > $HOME/.bash_profile"
    ]
  }
}

resource "null_resource" "start-blue-squid-nodes" {
  count = length(local.blue_squid_node_ip_v4)

  depends_on = [null_resource.setup-blue-squid-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.blue-squid-node-config.deployment-color
  }

  connection {
    host           = local.blue_squid_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"

  }

  provisioner "file" {
    source      = "${var.path_to_configs}/nginx-squid.conf"
    destination = "/home/${var.ssh_user}/squid/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/cors-settings.conf"
    destination = "/home/${var.ssh_user}/squid/cors-settings.conf"
  }
  # copy nginx install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_nginx.sh"
    destination = "/home/${var.ssh_user}/squid/install_nginx.sh"
  }

  # install deployments
  provisioner "remote-exec" {
    inline = [
      # install nginx, certbot, docker and docker compose
      "chmod +x /home/${var.ssh_user}/squid/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/squid/install_docker.sh",
      "sudo DEBIAN_FRONTEND=noninteractive apt install nginx certbot python3-certbot-nginx --no-install-recommends -y",
      # copy files
      "sudo cp -f /home/${var.ssh_user}/squid/cors-settings.conf /etc/nginx/cors-settings.conf",
      "sudo cp -f /home/${var.ssh_user}/squid/backend.conf /etc/nginx/backend.conf",
      "chmod +x /home/${var.ssh_user}/squid/install_nginx.sh",
      "sudo bash /home/${var.ssh_user}/squid/install_nginx.sh",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot certonly --dry-run --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.blue-squid-node-config.domain-prefix}.squid.${var.blue-squid-node-config.network-name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname ${var.blue-squid-node-config.domain-prefix}-squid-${var.blue-squid-node-config.network-name}",
      # create .env file
      "chmod +x /home/${var.ssh_user}/squid/set_env_vars.sh",
      "bash /home/${var.ssh_user}/squid/set_env_vars.sh",
      "source /.bash_profile",
      # create docker compose file
      "chmod +x /home/${var.ssh_user}/squid/create_compose_file.sh",
      "bash /home/${var.ssh_user}/squid/create_compose_file.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl stop docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f ./archive/docker-compose.yml up -d",
      "echo 'Installation Complete'",
    ]
  }

}


resource "null_resource" "start-green-squid-nodes" {
  count = length(local.green_squid_node_ip_v4)

  depends_on = [null_resource.setup-green-squid-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.green-squid-node-config.deployment-color
  }

  connection {
    host           = local.green_squid_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"

  }

  provisioner "file" {
    source      = "${var.path_to_configs}/nginx-squid.conf"
    destination = "/home/${var.ssh_user}/squid/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/cors-settings.conf"
    destination = "/home/${var.ssh_user}/squid/cors-settings.conf"
  }
  # copy nginx install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_nginx.sh"
    destination = "/home/${var.ssh_user}/squid/install_nginx.sh"
  }

  # install deployments
  provisioner "remote-exec" {
    inline = [
      # install nginx, certbot, docker and docker compose
      "chmod +x /home/${var.ssh_user}/squid/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/squid/install_docker.sh",
      "sudo DEBIAN_FRONTEND=noninteractive apt install nginx certbot python3-certbot-nginx --no-install-recommends -y",
      # copy files
      "sudo cp -f /home/${var.ssh_user}/squid/cors-settings.conf /etc/nginx/cors-settings.conf",
      "sudo cp -f /home/${var.ssh_user}/squid/backend.conf /etc/nginx/backend.conf",
      "chmod +x /home/${var.ssh_user}/squid/install_nginx.sh",
      "sudo bash /home/${var.ssh_user}/squid/install_nginx.sh",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot certonly --dry-run --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.green-squid-node-config.domain-prefix}.squid.${var.green-squid-node-config.network-name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname ${var.green-squid-node-config.domain-prefix}-squid-${var.green-squid-node-config.network-name}",
      # create .env file
      "chmod +x /home/${var.ssh_user}/squid/set_env_vars.sh",
      "bash /home/${var.ssh_user}/squid/set_env_vars.sh",
      "source /.bash_profile",
      # create docker compose file
      "chmod +x /home/${var.ssh_user}/squid/create_compose_file.sh",
      "bash /home/${var.ssh_user}/squid/create_compose_file.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl stop docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f ./archive/docker-compose.yml up -d",
      "echo 'Installation Complete'",
    ]
  }

}
