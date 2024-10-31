locals {
  nova_blue_subql_node_ip_v4 = flatten([
    [aws_instance.nova_subql_blue_node.*.public_ip],
    ]
  )

  nova_green_subql_node_ip_v4 = flatten([
    [aws_instance.nova_subql_green_node.*.public_ip],
    ]
  )
}

resource "null_resource" "setup-nova-blue-subql-nodes" {
  count = length(local.nova_blue_subql_node_ip_v4)

  depends_on = [aws_instance.nova_subql_blue_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.nova_blue_subql_node_ip_v4)
  }

  lifecycle {
    ignore_changes = [triggers]
  }
  connection {
    host           = local.nova_blue_subql_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"
  }

  # create subql dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/${var.ssh_user}/subql",
      "sudo mkdir -p /home/${var.ssh_user}/subql/postgresql",
      "sudo mkdir -p /home/${var.ssh_user}/subql/postgresql/conf",
      "sudo mkdir -p /home/${var.ssh_user}/subql/postgresql/data",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subql/ && sudo chmod -R 750 /home/${var.ssh_user}/subql/"
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path_to_configs}/postgresql.conf"
    destination = "/home/${var.ssh_user}/subql/postgresql/conf/postgresql.conf"
  }

  # copy subql launch script
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_subql_stack.sh"
    destination = "/home/${var.ssh_user}/subql/subql_stack.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/subql/install_docker.sh"
  }

  # copy nginx config files
  provisioner "file" {
    source      = "${var.path_to_configs}/nginx-subql.conf"
    destination = "/home/${var.ssh_user}/subql/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/cors-settings.conf"
    destination = "/home/${var.ssh_user}/subql/cors-settings.conf"
  }
  # copy nginx install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_nginx.sh"
    destination = "/home/${var.ssh_user}/subql/install_nginx.sh"
  }

}

resource "null_resource" "setup-nova-green-subql-nodes" {
  count = length(local.green_subql_node_ip_v4)

  depends_on = [aws_instance.nova_subql_green_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.nova_green_subql_node_ip_v4)
  }

  lifecycle {
    ignore_changes = [triggers]
  }

  connection {
    host           = local.nova_green_subql_node_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    private_key    = file("${var.private_key_path}")
    timeout        = "300s"
  }

  # create subql dir
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.ssh_user}/subql",
      "mkdir -p /home/${var.ssh_user}/subql/postgresql",
      "mkdir -p /home/${var.ssh_user}/subql/postgresql/{conf,data}",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subql/ && sudo chmod -R 750 /home/${var.ssh_user}/subql/"
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path_to_configs}/postgresql.conf"
    destination = "/home/${var.ssh_user}/subql/postgresql/conf/postgresql.conf"
  }

  # copy subql launch script
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_subql_stack.sh"
    destination = "/home/${var.ssh_user}/subql/subql_stack.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/subql/install_docker.sh"
  }

  # copy nginx config files
  provisioner "file" {
    source      = "${var.path_to_configs}/nginx-subql.conf"
    destination = "/home/${var.ssh_user}/subql/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/cors-settings.conf"
    destination = "/home/${var.ssh_user}/subql/cors-settings.conf"
  }
  # copy nginx install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_nginx.sh"
    destination = "/home/${var.ssh_user}/subql/install_nginx.sh"
  }

}

resource "null_resource" "start-nova-blue-subql-nodes" {
  count = length(local.nova_blue_subql_node_ip_v4)

  depends_on = [null_resource.setup-nova-blue-subql-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.blue-subql-node-config.deployment-color
  }

  connection {
    host           = local.nova_blue_subql_node_ip_v4[count.index]
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
      "chmod +x /home/${var.ssh_user}/subql/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_docker.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl restart docker.service",
      # copy files
      "sudo cp -f /home/${var.ssh_user}/subql/cors-settings.conf /etc/nginx/cors-settings.conf",
      "sudo cp -f /home/${var.ssh_user}/subql/backend.conf /etc/nginx/backend.conf",
      "chmod +x /home/${var.ssh_user}/subql/install_nginx.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_nginx.sh",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.blue-subql-node-config.domain-prefix}.${var.network_name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname subql-${var.blue-subql-node-config.network-name}",

      # create .env file
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/subql/.env",
      "echo DOCKER_TAG=${var.blue-subql-node-config.docker-tag} >> /home/${var.ssh_user}/subql/.env",
      "echo POSTGRES_PASSWORD=${var.postgres_password} >> /home/${var.ssh_user}/subql/.env",
      "echo HASURA_GRAPHQL_ADMIN_SECRET=${var.hasura_graphql_admin_secret} >> /home/${var.ssh_user}/subql/.env",

      # run subql lauch script
      "chmod +x /home/${var.ssh_user}/subql/subql_stack.sh",
      "bash /home/${var.ssh_user}/subql/subql_stack.sh",
      "echo 'Installation Complete'",
    ]
  }

}


resource "null_resource" "nova-start-green-subql-nodes" {
  count = length(local.nova_green_subql_node_ip_v4)

  depends_on = [null_resource.setup-nova-green-subql-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.green-subql-node-config.deployment-color
  }

  connection {
    host           = local.green_subql_node_ip_v4[count.index]
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
      "chmod +x /home/${var.ssh_user}/subql/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_docker.sh",
      # install nginx
      "chmod +x /home/${var.ssh_user}/subql/install_nginx.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_nginx.sh",
    ]
  }

  # install deployments
  provisioner "remote-exec" {
    inline = [
      # install nginx, certbot, docker and docker compose
      "chmod +x /home/${var.ssh_user}/subql/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_docker.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl restart docker.service",
      # copy files
      "sudo cp -f /home/${var.ssh_user}/subql/cors-settings.conf /etc/nginx/cors-settings.conf",
      "sudo cp -f /home/${var.ssh_user}/subql/backend.conf /etc/nginx/backend.conf",
      "chmod +x /home/${var.ssh_user}/subql/install_nginx.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_nginx.sh",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d subql.${var.network_name}.subspace.network -d ${var.green-subql-node-config.domain-prefix}.${var.network_name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname subql-${var.green-subql-node-config.deployment-color}-${var.green-subql-node-config.network-name}",

      # create .env file
      "echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/subql/.env",
      "echo DOCKER_TAG=${var.blue-subql-node-config.docker-tag} >> /home/${var.ssh_user}/subql/.env",
      "echo POSTGRES_PASSWORD=${var.postgres_password} >> /home/${var.ssh_user}/subql/.env",
      "echo HASURA_GRAPHQL_ADMIN_SECRET=${var.hasura_graphql_admin_secret} >> /home/${var.ssh_user}/subql/.env",
      "echo HASURA_GRAPHQL_JWT_SECRET=${var.hasura_graphql_jwt_secret} >> /home/${var.ssh_user}/subql/.env",

      # run subql lauch script
      "chmod +x /home/${var.ssh_user}/subql/subql_stack.sh",
      "bash /home/${var.ssh_user}/subql/subql_stack.sh",
      "echo 'Installation Complete'",
    ]
  }

}
