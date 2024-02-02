locals {
  nova_archive_node_ip_v4 = flatten([
    [aws_instance.nova_archive_node.*.public_ip],
    ]
  )
}

resource "null_resource" "setup-nova-archive-nodes" {
  count = length(local.nova_archive_node_ip_v4)

  depends_on = [aws_security_group.gemini-squid-sg, cloudflare_record.nova-archive]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.nova_archive_node_ip_v4)
  }

  connection {
    host           = local.nova_archive_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"
  }

  # create archive dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/${var.ssh_user}/archive/",
      "sudo mkdir -p /home/${var.ssh_user}/archive/postgresql/data",
      "sudo mkdir -p /home/${var.ssh_user}/archive/node-data",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/archive/ && sudo chmod -R 750 /home/${var.ssh_user}/archive/"
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path_to_configs}/postgresql.conf"
    destination = "/home/${var.ssh_user}/archive/postgresql/postgresql.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_nova_archive_node_compose_file.sh"
    destination = "/home/${var.ssh_user}/archive/create_compose_file.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/archive/install_docker.sh"
  }

  # copy nginx config files
  provisioner "file" {
    source      = "${var.path_to_configs}/nginx-archive.conf"
    destination = "/home/${var.ssh_user}/archive/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/cors-settings.conf"
    destination = "/home/${var.ssh_user}/archive/cors-settings.conf"
  }

  # copy nginx install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_nginx.sh"
    destination = "/home/${var.ssh_user}/archive/install_nginx.sh"
  }

}

resource "null_resource" "prune-nova-archive-nodes" {
  count      = var.nova-archive-node-config.prune ? length(local.nova_archive_node_ip_v4) : 0
  depends_on = [null_resource.setup-nova-archive-nodes]

  triggers = {
    prune = var.nova-archive-node-config.prune
  }

  connection {
    host           = local.nova_archive_node_ip_v4[count.index]
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
      "sudo docker ps -aq | xargs sudo docker stop",
      "sudo docker system prune -a -f && sudo docker volume ls -q | xargs sudo docker volume rm -f",
      "cat /dev/null > $HOME/.bash_profile",
    ]
  }
}


resource "null_resource" "start-nova-archive-nodes" {
  count = length(local.nova_archive_node_ip_v4)

  depends_on = [null_resource.setup-nova-archive-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_version = var.nova-archive-node-config.deployment-version
  }

  connection {
    host           = local.nova_archive_node_ip_v4[count.index]
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
      "chmod +x /home/${var.ssh_user}/archive/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/archive/install_docker.sh",
      # install nginx
      "chmod +x /home/${var.ssh_user}/archive/install_nginx.sh",
      "sudo bash /home/${var.ssh_user}/archive/install_nginx.sh",
    ]
  }

  # install deployments
  provisioner "remote-exec" {
    inline = [
      # copy files
      "sudo cp -f /home/${var.ssh_user}/archive/cors-settings.conf /etc/nginx/cors-settings.conf",
      "sed -i -e 's/server_name _/server_name ${var.nova-archive-node-config.domain-prefix}.${var.network_name}.subspace.network/g' /home/${var.ssh_user}/archive/backend.conf",
      "sudo cp -f /home/${var.ssh_user}/archive/backend.conf /etc/nginx/backend.conf",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.nova-archive-node-config.domain-prefix}.${var.network_name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname archive-${var.network_name}",
      # create .env file
      "echo NODE_ORG=${var.nova-archive-node-config.node-org} > /home/${var.ssh_user}/archive/.env",
      "echo NODE_TAG=${var.nova-archive-node-config.node-tag} >> /home/${var.ssh_user}/archive/.env",
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/archive/.env",
      "echo DOMAIN_PREFIX=${var.nova-archive-node-config.domain-prefix} >> /home/${var.ssh_user}/archive/.env",
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/archive/.env",
      "echo DOCKER_TAG=${var.nova-archive-node-config.docker-tag} >> /home/${var.ssh_user}/archive/.env",
      "echo NODE_NAME=SUBSQUID_GEMINI_3g >> /home/${var.ssh_user}/archive/.env",
      "echo POSTGRES_HOST=db >> /home/${var.ssh_user}/archive/.env",
      "echo POSTGRES_PORT=5432 >> /home/${var.ssh_user}/archive/.env",
      "echo POSTGRES_USER=postgres >> /home/${var.ssh_user}/archive/.env",
      "echo POSTGRES_DB=squid-archive >> /home/${var.ssh_user}/archive/.env",
      "echo POSTGRES_PASSWORD=${var.postgres_password} >> /home/${var.ssh_user}/archive/.env",
      "echo DB_TYPE=postgres >> /home/${var.ssh_user}/archive/.env",
      "echo DB_HOST=db >> /home/${var.ssh_user}/archive/.env",
      "echo DB_PORT=5432 >> /home/${var.ssh_user}/archive/.env",
      "echo DB_USER=postgres >> /home/${var.ssh_user}/archive/.env",
      "echo DB_NAME=squid-archive >> /home/${var.ssh_user}/archive/.env",
      "echo DB_PASS=${var.postgres_password} >> /home/${var.ssh_user}/archive/.env",
      "echo PROCESSOR_HEALTH_HOST=http://processor:3000 >> /home/${var.ssh_user}/archive/.env",
      "echo PROCESSOR_HEALTH_PORT=7070 >> /home/${var.ssh_user}/archive/.env",
      "echo HEALTH_CHECK_PORT=8080 >> /home/${var.ssh_user}/archive/.env",
      "echo INGEST_HEALTH_HOST=http://ingest:9090 >> /home/${var.ssh_user}/archive/.env",
      "echo INGEST_HEALTH_PORT=7070 >> /home/${var.ssh_user}/archive/.env",
      "echo MY_SECRET=${var.prometheus_secret} >> /home/${var.ssh_user}/archive/.env",

      # create docker compose file
      "chmod +x /home/${var.ssh_user}/archive/create_compose_file.sh",
      "bash /home/${var.ssh_user}/archive/create_compose_file.sh",

      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f /home/${var.ssh_user}/archive/docker-compose.yml up -d",
      "echo 'Installation Complete'"
    ]
  }
}
