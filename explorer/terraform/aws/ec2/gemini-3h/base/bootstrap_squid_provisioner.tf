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

  depends_on = [aws_instance.squid_blue_node]

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
      "sudo mkdir -p /home/${var.ssh_user}/squid/postgresql/conf",
      "sudo mkdir -p /home/${var.ssh_user}/squid/postgresql/data",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/squid/ && sudo chmod -R 750 /home/${var.ssh_user}/squid/"
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

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/squid/install_docker.sh"
  }

  # copy nginx config files
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

}

resource "null_resource" "setup-green-squid-nodes" {
  count = length(local.green_squid_node_ip_v4)

  depends_on = [aws_instance.squid_green_node]

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
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/squid/ && sudo chmod -R 750 /home/${var.ssh_user}/squid/"
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

  # copy nginx config files
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
      "sudo docker ps -aq | xargs sudo docker stop",
      "sudo docker system prune -a -f && sudo docker volume ls -q | xargs sudo docker volume rm -f",
      "cat /dev/null > $HOME/.bash_profile",
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

  # install deployments
  provisioner "remote-exec" {
    inline = [
      # install nginx, certbot, docker and docker compose
      "chmod +x /home/${var.ssh_user}/squid/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/squid/install_docker.sh",
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
      "sudo certbot --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d squid.${var.network_name}.subspace.network -d ${var.blue-squid-node-config.domain-prefix}.squid.${var.network_name}.subspace.network",
      "sudo systemctl restart nginx",
      # install netdata
      "sudo sh -c \"curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud\"",
      # set hostname
      "sudo hostnamectl set-hostname squid-${var.blue-squid-node-config.network-name}",

      # create .env file
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/squid/.env",
      "echo DOMAIN_PREFIX=${var.blue-squid-node-config.domain-prefix} >> /home/${var.ssh_user}/squid/.env",
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/squid/.env",
      "echo DOCKER_TAG=${var.blue-squid-node-config.docker-tag} >> /home/${var.ssh_user}/squid/.env",
      "echo NODE_NAME=SUBSQUID_GEMINI_3h >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_HOST=db >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_PORT=5432 >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_USER=postgres >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_DB=squid-archive >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_PASSWORD=${var.postgres_password} >> /home/${var.ssh_user}/squid/.env",
      "echo DB_TYPE=postgres >> /home/${var.ssh_user}/squid/.env",
      "echo DB_HOST=db >> /home/${var.ssh_user}/squid/.env",
      "echo DB_PORT=5432 >> /home/${var.ssh_user}/squid/.env",
      "echo DB_USER=postgres >> /home/${var.ssh_user}/squid/.env",
      "echo DB_NAME=squid-archive >> /home/${var.ssh_user}/squid/.env",
      "echo DB_PASS=${var.postgres_password} >> /home/${var.ssh_user}/squid/.env",
      "echo ARCHIVE_ENDPOINT=https://archive.gemini-3h.subspace.network/api >> /home/${var.ssh_user}/squid/.env",
      "echo CHAIN_RPC_ENDPOINT=wss://rpc-0.gemini-3h.subspace.network/ws >> /home/${var.ssh_user}/squid/.env",
      "echo PROCESSOR_HEALTH_HOST=http://processor:3000 >> /home/${var.ssh_user}/squid/.env",
      "echo PROCESSOR_HEALTH_PORT=7070 >> /home/${var.ssh_user}/squid/.env",
      "echo HEALTH_CHECK_PORT=8080 >> /home/${var.ssh_user}/squid/.env",
      "echo INGEST_HEALTH_HOST=http://ingest:9090 >> /home/${var.ssh_user}/squid/.env",
      "echo INGEST_HEALTH_PORT=7070 >> /home/${var.ssh_user}/squid/.env",
      "echo MY_SECRET=${var.prometheus_secret} >> /home/${var.ssh_user}/squid/.env",

      # create docker compose file
      "chmod +x /home/${var.ssh_user}/squid/create_compose_file.sh",
      "bash /home/${var.ssh_user}/squid/create_compose_file.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f ./squid/docker-compose.yml up -d",
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

  # install nginx, certbot, docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ssh_user}/squid/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/squid/install_docker.sh",
      # install nginx
      "chmod +x /home/${var.ssh_user}/squid/install_nginx.sh",
      "sudo bash /home/${var.ssh_user}/squid/install_nginx.sh",
    ]
  }

  # install deployments
  provisioner "remote-exec" {
    inline = [
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
      "sudo certbot --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d squid.${var.network_name}.subspace.network -d ${var.green-squid-node-config.domain-prefix}.${var.network_name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname squid-${var.green-squid-node-config.network-name}",
      # create .env file
      "echo NETWORK_NAME=${var.network_name} >> /home/${var.ssh_user}/squid/.env",
      "echo DOMAIN_PREFIX=${var.green-squid-node-config.domain-prefix} >> /home/${var.ssh_user}/squid/.env",
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/squid/.env",
      "echo DOCKER_TAG=${var.green-squid-node-config.docker-tag} >> /home/${var.ssh_user}/squid/.env",
      "echo NODE_NAME=SUBSQUID_GEMINI_3h >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_HOST=db >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_PORT=5432 >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_USER=postgres >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_DB=squid-archive >> /home/${var.ssh_user}/squid/.env",
      "echo POSTGRES_PASSWORD=${var.postgres_password} >> /home/${var.ssh_user}/squid/.env",
      "echo DB_TYPE=postgres >> /home/${var.ssh_user}/squid/.env",
      "echo DB_HOST=db >> /home/${var.ssh_user}/squid/.env",
      "echo DB_PORT=5432 >> /home/${var.ssh_user}/squid/.env",
      "echo DB_USER=postgres >> /home/${var.ssh_user}/squid/.env",
      "echo DB_NAME=squid-archive >> /home/${var.ssh_user}/squid/.env",
      "echo DB_PASS=${var.postgres_password} >> /home/${var.ssh_user}/squid/.env",
      "echo ARCHIVE_ENDPOINT=https://archive.gemini-3h.subspace.network/api >> /home/${var.ssh_user}/squid/.env",
      "echo CHAIN_RPC_ENDPOINT=wss://rpc-0.gemini-3h.subspace.network/ws >> /home/${var.ssh_user}/squid/.env",
      "echo PROCESSOR_HEALTH_HOST=http://processor:3000 >> /home/${var.ssh_user}/squid/.env",
      "echo PROCESSOR_HEALTH_PORT=7070 >> /home/${var.ssh_user}/squid/.env",
      "echo HEALTH_CHECK_PORT=8080 >> /home/${var.ssh_user}/squid/.env",
      "echo INGEST_HEALTH_HOST=http://ingest:9090 >> /home/${var.ssh_user}/squid/.env",
      "echo INGEST_HEALTH_PORT=7070 >> /home/${var.ssh_user}/squid/.env",
      "echo MY_SECRET=${var.prometheus_secret} >> /home/${var.ssh_user}/squid/.env",

      # create docker compose file
      "chmod +x /home/${var.ssh_user}/squid/create_compose_file.sh",
      "bash /home/${var.ssh_user}/squid/create_compose_file.sh",

      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f ./squid/docker-compose.yml up -d",
      "echo 'Installation Complete'",
    ]
  }

}
