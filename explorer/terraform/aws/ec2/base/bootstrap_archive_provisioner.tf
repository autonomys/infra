locals {
  archive_node_ip_v4 = flatten([
    [aws_instance.archive_node.*.public_ip],
    ]
  )
}


resource "null_resource" "setup-archive-nodes" {
  count = length(local.archive_node_ip_v4)

  depends_on = [cloudflare_record.archive]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.archive_node_ip_v4)
  }

  connection {
    host           = local.archive_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    timeout        = "300s"
  }

  # create archive dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /mnt/archive",
      "sudo mount -o defaults,nofail,discard,noatime /dev/sda /mnt/archive",
      "echo '/dev/sda /mnt/archive ext4 defaults,nofail,discard,noatime 0 0' >> /etc/fstab",
      "cd / && sudo ln -s /mnt/archive /archive ",
      "sudo mkdir -p /archive/postgresql/data",
      "sudo mkdir -p /archive/node-data && chown -R nobody:nogroup /archive/node-data",
    ]
  }

  # copy postgres config file
  provisioner "file" {
    source      = "${var.path-to-configs}/postgresql.conf"
    destination = "/archive/postgresql/postgresql.conf"
  }

  # copy compose file creation script
  provisioner "file" {
    source      = "${var.path-to-scripts}/create_archive_node_compose_file.sh"
    destination = "/archive/create_compose_file.sh"
  }

  provisioner "file" {
    source      = "${var.path-to-scripts}/set_env_vars.sh"
    destination = "/archive/set_env_vars.sh"
  }

  # copy docker install file
  provisioner "file" {
    source      = "${var.path-to-scripts}/install_docker.sh"
    destination = "/archive/install_docker.sh"
  }  # copy nginx configs

}

resource "null_resource" "prune-archive-nodes" {
  count      = var.archive-node-config.prune ? length(local.archive_node_ip_v4) : 0
  depends_on = [null_resource.setup-archive-nodes]

  triggers = {
    prune = var.archive-node-config.prune
  }

  connection {
    host           = local.archive_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    timeout        = "300s"
  }

  # prune network
  provisioner "remote-exec" {
    inline = [
      "docker ps -aq | xargs docker stop",
      "docker system prune -a -f && docker volume ls -q | xargs docker volume rm -f",
    ]
  }
}


resource "null_resource" "start-archive-nodes" {
  count = length(local.archive_node_ip_v4)

  depends_on = [null_resource.setup-archive-nodes]

  # trigger on node deployment environment change
  triggers = {
    deployment_color = var.archive-node-config.deployment-color
  }

  connection {
    host           = local.archive_node_ip_v4[count.index]
    user           = "root"
    type           = "ssh"
    agent          = true
    agent_identity = var.aws_key_name
    timeout        = "300s"
  }

  # install nginx, certbot, docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /archive/install_docker.sh",
      "sudo bash /archive/install_docker.sh",
      "sudo DEBIAN_FRONTEND=noninteractive apt install nginx certbot python3-certbot-nginx --no-install-recommends -y",
    ]
  }

  provisioner "file" {
    source      = "${var.path-to-configs}/nginx-archive.conf"
    destination = "/etc/nginx/backend.conf"
  }

  provisioner "file" {
    source      = "${var.path-to-configs}/cors-settings.conf"
    destination = "/etc/nginx/cors-settings.conf"
  }
  # copy nginx install file
  provisioner "file" {
    source      = "${var.path-to-scripts}/install_nginx.sh"
    destination = "/archive/install_nginx.sh"
  }


  # install deployments
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /archive/install_nginx.sh",
      "sudo bash /archive/install_nginx.sh",
      # start systemd services
      "sudo systemctl daemon-reload",
      # start nginx
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      # install certbot & generate domain
      "sudo certbot certonly --dry-run --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.archive-node-config.domain-prefix}-${count.index}.${var.archive-node-config.network-name}.subspace.network",
      "sudo systemctl restart nginx",
      # set hostname
      "hostnamectl set-hostname ${var.archive-node-config.domain-prefix}-${count.index}-${var.archive-node-config.network-name}",
      # create .env file
      "sudo chmod +x /archive/set_env_vars.sh",
      "sudo bash /archive/set_env_vars.sh",
      "source ~/.bash_profile",
      # create docker compose file
      "sudo chmod +x /archive/create_compose_file.sh",
      "sudo bash /archive/create_compose_file.sh",
      # change docker path to use secondary disk
      "sudo mv /var/lib/docker /archive/ && ln -s /archive/docker /var/lib/docker",
      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl stop docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f /archive/docker-compose.yml up -d",
      "echo 'Installation Complete'"
    ]
  }
}
