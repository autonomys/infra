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
      "sudo mkdir -p /explorer_squid",
      "sudo mount -o defaults,nofail,discard,noatime /dev/sda /explorer_squid",
      "echo '/dev/sda /mnt/explorer_squid ext4 defaults,nofail,discard,noatime 0 0' >> /etc/fstab"
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

  # install certbot and issue domain
  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt install nginx certbot python3-certbot-nginx --no-install-recommends -y",
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
      "sudo systemctl daemon-reload",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo certbot certonly --dry-run --nginx --non-interactive -v --agree-tos -m alerts@subspace.network -d ${var.explorer-node-config.domain-prefix}-${count.index}.${var.network-name}.subspace.network",
      "sudo systemctl restart nginx",

      # set hostname
      "hostnamectl set-hostname ${var.network-name}-explorer-squid-node-${count.index}",

      # create .env file
      "sudo chmod +x /explorer_squid/set_env_vars.sh",
      "sudo bash /explorer_squid/set_env_vars.sh",

      # create docker compose file
      "sudo chmod +x /explorer_squid/create_compose_file.sh",
      "sudo bash /explorer_squid/create_compose_file.sh",

      # start docker daemon
      "sudo systemctl enable --now docker.service",
      "sudo systemctl stop docker.service",
      "sudo systemctl restart docker.service",
      "sudo docker compose -f /explorer_squid/docker-compose.yml up -d",
      "echo 'Installation Complete'"
    ]
  }
}
