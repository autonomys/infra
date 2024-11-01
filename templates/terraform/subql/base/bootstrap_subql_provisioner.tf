locals {
  blue_subql_node_ip_v4 = flatten([
    [aws_instance.subql_blue_node.*.public_ip],
    ]
  )

  green_subql_node_ip_v4 = flatten([
    [aws_instance.subql_green_node.*.public_ip],
    ]
  )
}

resource "null_resource" "setup-blue-subql-nodes" {
  count = length(local.blue_subql_node_ip_v4)

  depends_on = [aws_instance.subql_blue_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.blue_subql_node_ip_v4)
  }

  lifecycle {
    ignore_changes = [triggers]
  }
  connection {
    host           = local.blue_subql_node_ip_v4[count.index]
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
    destination = "/home/${var.ssh_user}/subql/install_subql_stack.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/subql/install_docker.sh"
  }

}

resource "null_resource" "setup-green-subql-nodes" {
  count = length(local.green_subql_node_ip_v4)

  depends_on = [aws_instance.subql_green_node]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.green_subql_node_ip_v4)
  }

  lifecycle {
    ignore_changes = [triggers]
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
    destination = "/home/${var.ssh_user}/subql/install_subql_stack.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "/home/${var.ssh_user}/subql/install_docker.sh"
  }

}

resource "null_resource" "start-blue-subql-nodes" {
  count = length(local.blue_subql_node_ip_v4)

  depends_on = [null_resource.setup-blue-subql-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.blue-subql-node-config.deployment-color
  }

  connection {
    host           = local.blue_subql_node_ip_v4[count.index]
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
      # install docker and docker compose
      "chmod +x /home/${var.ssh_user}/subql/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_docker.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl restart docker.service",

      # Add ubuntu user to docker and sudo group
      "sudo usermod -aG docker ${var.ssh_user}",
      "sudo usermod -aG sudo ${var.ssh_user}",

      # set hostname
      "sudo hostnamectl set-hostname subql-${var.blue-subql-node-config.deployment-color}-${var.blue-subql-node-config.network-name}",

      # run subql install script
      "chmod +x /home/${var.ssh_user}/subql/install_subql_stack.sh",
      "bash /home/${var.ssh_user}/subql/install_subql_stack.sh",
      "echo 'Installation Complete'",

      # create .env file
      "grep -q '^NR_AGENT_IDENTIFIER=' /home/${var.ssh_user}/astral/.env && sed -i 's/^NR_AGENT_IDENTIFIER=.*/NR_AGENT_IDENTIFIER=subql-${var.blue-subql-node-config.deployment-color}-${var.blue-subql-node-config.network-name}/' /home/${var.ssh_user}/astral/.env || echo NR_AGENT_IDENTIFIER=subql-${var.blue-subql-node-config.deployment-color}-${var.blue-subql-node-config.network-name} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^NR_API_KEY=' /home/${var.ssh_user}/astral/.env && sed -i 's/^NR_API_KEY=.*/NR_API_KEY=${var.nr_api_key}/' /home/${var.ssh_user}/astral/.env || echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^DOCKER_TAG=' /home/${var.ssh_user}/astral/.env && sed -i 's/^DOCKER_TAG=.*/DOCKER_TAG=${var.blue-subql-node-config.docker-tag}/' /home/${var.ssh_user}/astral/.env || echo DOCKER_TAG=${var.blue-subql-node-config.docker-tag} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^DB_PASSWORD=' /home/${var.ssh_user}/astral/.env && sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=${var.postgres_password}/' /home/${var.ssh_user}/astral/.env || echo DB_PASSWORD=${var.postgres_password} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^HASURA_GRAPHQL_ADMIN_SECRET=' /home/${var.ssh_user}/astral/.env && sed -i 's/^HASURA_GRAPHQL_ADMIN_SECRET=.*/HASURA_GRAPHQL_ADMIN_SECRET=${var.hasura_graphql_admin_secret}/' /home/${var.ssh_user}/astral/.env || echo HASURA_GRAPHQL_ADMIN_SECRET=${var.hasura_graphql_admin_secret} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^HASURA_GRAPHQL_JWT_SECRET=' /home/${var.ssh_user}/astral/.env && sed -i 's|^HASURA_GRAPHQL_JWT_SECRET=.*|HASURA_GRAPHQL_JWT_SECRET={\"type\":\"HS256\",\"key\":\"${var.hasura_graphql_jwt_secret}\"}|' /home/${var.ssh_user}/astral/.env || echo HASURA_GRAPHQL_JWT_SECRET={\"type\":\"HS256\",\"key\":\"${var.hasura_graphql_jwt_secret}\"} >> /home/${var.ssh_user}/astral/.env",

      "echo 'Installation Complete'",
    ]
  }

}


resource "null_resource" "start-green-subql-nodes" {
  count = length(local.green_subql_node_ip_v4)

  depends_on = [null_resource.setup-green-subql-nodes]

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

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ssh_user}/subql/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_docker.sh",
    ]
  }

  # install deployments
  provisioner "remote-exec" {
    inline = [
      # install docker and docker compose
      "chmod +x /home/${var.ssh_user}/subql/install_docker.sh",
      "sudo bash /home/${var.ssh_user}/subql/install_docker.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl restart docker.service",

      # Add ubuntu user to docker and sudo group
      "sudo usermod -aG docker ${var.ssh_user}",
      "sudo usermod -aG sudo ${var.ssh_user}",

      # set hostname
      "sudo hostnamectl set-hostname subql-${var.green-subql-node-config.deployment-color}-${var.green-subql-node-config.network-name}",

      # run subql install script
      "chmod +x /home/${var.ssh_user}/subql/install_subql_stack.sh",
      "bash /home/${var.ssh_user}/subql/install_subql_stack.sh",
      "echo 'Installation Complete'",

      # create .env file
      "grep -q '^NR_AGENT_IDENTIFIER=' /home/${var.ssh_user}/astral/.env && sed -i 's/^NR_AGENT_IDENTIFIER=.*/NR_AGENT_IDENTIFIER=subql-${var.green-subql-node-config.deployment-color}-${var.green-subql-node-config.network-name}/' /home/${var.ssh_user}/astral/.env || echo NR_AGENT_IDENTIFIER=subql-${var.green-subql-node-config.deployment-color}-${var.green-subql-node-config.network-name} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^NR_API_KEY=' /home/${var.ssh_user}/astral/.env && sed -i 's/^NR_API_KEY=.*/NR_API_KEY=${var.nr_api_key}/' /home/${var.ssh_user}/astral/.env || echo NR_API_KEY=${var.nr_api_key} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^DOCKER_TAG=' /home/${var.ssh_user}/astral/.env && sed -i 's/^DOCKER_TAG=.*/DOCKER_TAG=${var.green-subql-node-config.docker-tag}/' /home/${var.ssh_user}/astral/.env || echo DOCKER_TAG=${var.green-subql-node-config.docker-tag} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^DB_PASSWORD=' /home/${var.ssh_user}/astral/.env && sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=${var.postgres_password}/' /home/${var.ssh_user}/astral/.env || echo DB_PASSWORD=${var.postgres_password} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^HASURA_GRAPHQL_ADMIN_SECRET=' /home/${var.ssh_user}/astral/.env && sed -i 's/^HASURA_GRAPHQL_ADMIN_SECRET=.*/HASURA_GRAPHQL_ADMIN_SECRET=${var.hasura_graphql_admin_secret}/' /home/${var.ssh_user}/astral/.env || echo HASURA_GRAPHQL_ADMIN_SECRET=${var.hasura_graphql_admin_secret} >> /home/${var.ssh_user}/astral/.env",
      "grep -q '^HASURA_GRAPHQL_JWT_SECRET=' /home/${var.ssh_user}/astral/.env && sed -i 's|^HASURA_GRAPHQL_JWT_SECRET=.*|HASURA_GRAPHQL_JWT_SECRET={\"type\":\"HS256\",\"key\":\"${var.hasura_graphql_jwt_secret}\"}|' /home/${var.ssh_user}/astral/.env || echo HASURA_GRAPHQL_JWT_SECRET={\"type\":\"HS256\",\"key\":\"${var.hasura_graphql_jwt_secret}\"} >> /home/${var.ssh_user}/astral/.env",

      "echo 'Installation Complete'",
    ]
  }

}
