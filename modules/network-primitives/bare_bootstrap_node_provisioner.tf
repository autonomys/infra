resource "null_resource" "setup-bare-consensus-bootstrap-nodes" {
  count = var.bare-consensus-bootstrap-node-config == null ? 0 : length(var.bare-consensus-bootstrap-node-config.bootstrap-nodes)

  connection {
    host           = var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].ipv4
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # init node
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

resource "null_resource" "start-bare-consensus-boostrap-nodes" {
  count      = var.bare-consensus-bootstrap-node-config == null ? 0 : length(var.bare-consensus-bootstrap-node-config.bootstrap-nodes)
  depends_on = [null_resource.setup-bare-consensus-bootstrap-nodes]

  # trigger node re-deployment if anything changes in the node config
  triggers = var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index]

  connection {
    host           = var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].ipv4
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
      sudo hostnamectl set-hostname ${var.network_name}-bootstrap-node-${var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest bootstrap \
            --node-id ${var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].index} \
            --docker-tag ${var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].docker-tag} \
            --external-ip-v4 ${var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].ipv4} \
            --sync-mode ${var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].sync-mode} \
            --is-reserved ${var.bare-consensus-bootstrap-node-config.bootstrap-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d

      # delete config file
      sudo rm -rf /home/${var.ssh_user}/subspace/config.toml
      EOT
    ]
  }
}
