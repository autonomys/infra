locals {
  archive_node_ip_v4 = flatten([
    [aws_instance.archive_node.*.public_ip],
    ]
  )
}


resource "null_resource" "setup-archive-nodes" {
  count = length(local.archive_node_ip_v4)

  depends_on = [aws_security_group.gemini-squid-sg, cloudflare_record.archive]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.archive_node_ip_v4)
  }

  connection {
    host           = local.archive_node_ip_v4[count.index]
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
      "mkdir -p ./archive",
      "mkdir -p ./archive/postgresql/data",
      "mkdir -p ./archive/node-data",
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path_to_configs}/postgresql.conf"
    destination = "./archive/postgresql/postgresql.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path_to_scripts}/create_archive_node_compose_file.sh"
    destination = "./archive/create_compose_file.sh"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/set_env_vars.sh"
    destination = "./archive/set_env_vars.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_docker.sh"
    destination = "./archive/install_docker.sh"
  }

}

resource "null_resource" "prune-archive-nodes" {
  count      = var.archive-node-config.prune ? length(local.archive_node_ip_v4) : 0
  depends_on = [null_resource.setup-archive-nodes]

  triggers = {
    prune = var.archive-node-config.prune
  }

  connection {
    host           = local.archive_node_ip_v4[count.index]
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
      "cat /dev/null > $HOME/.bash_profile",
    ]
  }
}


resource "null_resource" "start-archive-nodes" {
  count = length(local.archive_node_ip_v4)

  depends_on = [null_resource.setup-archive-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_version = var.archive-node-config.deployment-version
  }

  connection {
    host           = local.archive_node_ip_v4[count.index]
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
      "chmod +x ./archive/install_docker.sh",
      "sudo bash ./archive/install_docker.sh",
      "sudo DEBIAN_FRONTEND=noninteractive apt install nginx certbot python3-certbot-nginx --no-install-recommends -y",
    ]
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/nginx-archive.conf"
    destination = "./archive/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path_to_configs}/cors-settings.conf"
    destination = "./archive/cors-settings.conf"
  }
  # copy nginx install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/install_nginx.sh"
    destination = "./archive/install_nginx.sh"
  }


  # install deployments
  provisioner "remote-exec" {
    inline = [
      # copy files
      "sudo cp -f ./archive/cors-settings.conf /etc/nginx/cors-settings.conf",
      "sudo cp -f ./archive/backend.conf /etc/nginx/backend.conf",
      "chmod +x ./archive/install_nginx.sh",
      "sudo bash ./archive/install_nginx.sh",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot certonly --dry-run --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.archive-node-config.domain-prefix}.archive.${var.network_name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "sudo hostnamectl set-hostname ${var.archive-node-config.domain-prefix}-archive-${var.network_name}",
      # create .env file
      "chmod +x ./archive/set_env_vars.sh",
      "bash ./archive/set_env_vars.sh",
      "source /.bash_profile",
      # create docker compose file
      "chmod +x ./archive/create_compose_file.sh",
      "bash ./archive/create_compose_file.sh",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl stop docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f ./archive/docker-compose.yml up -d",
      "echo 'Installation Complete'"
    ]
  }
}
