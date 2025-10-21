resource "null_resource" "setup-bare-domain-bootstrap-nodes" {
  count = var.bare-domain-bootstrap-node-config == null ? 0 : length(var.bare-domain-bootstrap-node-config.bootstrap-nodes)

  connection {
    host           = var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].ipv4
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo apt update -y
      sudo mkdir -p /home/${var.ssh_user}/subspace/
      sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.ssh_user}/subspace/
      EOT
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/installer.sh"
    destination = "/home/${var.ssh_user}/subspace/installer.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo bash /home/${var.ssh_user}/subspace/installer.sh
      EOT
    ]
  }

}

resource "null_resource" "start-bare-domain-bootstrap-nodes" {
  count      = var.bare-domain-bootstrap-node-config == null ? 0 : length(var.bare-domain-bootstrap-node-config.bootstrap-nodes)
  depends_on = [null_resource.setup-bare-domain-bootstrap-nodes]

  # trigger node deployment of the node object changes
  triggers = var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index]

  connection {
    host           = var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].ipv4
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # copy config file
  provisioner "file" {
    source      = "./config.toml"
    destination = "/home/${var.ssh_user}/subspace/config.toml"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # stop any running service
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down

      # set hostname
      sudo hostnamectl set-hostname ${var.network_name}-domain-${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id}-bootstrap-node-${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest domain-bootstrap \
          --network ${var.network_name} \
          --new-relic-api-key ${var.new_relic_api_key} \
          --fqdn ${var.cloudflare_domain_fqdn} \
          --node-id ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].index} \
          --docker-tag ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].ipv4} \
          --node-prefix ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-name} \
          --domain-id ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id} \
          --sync-mode ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].sync-mode} \
          --is-reserved ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d

      # delete config file
      sudo rm -rf /home/${var.ssh_user}/subspace/config.toml
      EOT
    ]
  }
}
