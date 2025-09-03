resource "null_resource" "setup_timekeeper_nodes" {
  count = var.timekeeper-node-config == null ? 0 : length(var.timekeeper-node-config.timekeeper-nodes)

  connection {
    host           = var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4
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

  # install docker and docker compose and LE script
  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/${var.ssh_user}/subspace/installer.sh",
    ]
  }

}

resource "null_resource" "start_timekeeper_nodes" {
  count      = var.timekeeper-node-config == null ? 0 : length(var.timekeeper-node-config.timekeeper-nodes)
  depends_on = [null_resource.setup_timekeeper_nodes]

  # trigger node deployment on node object change
  triggers = var.timekeeper-node-config.timekeeper-nodes[count.index]

  connection {
    host           = var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4
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
      sudo hostnamectl set-hostname ${var.network_name}-timekeeper-node-${var.timekeeper-node-config.timekeeper-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest timekeeper \
          --node-id ${var.timekeeper-node-config.timekeeper-nodes[count.index].index} \
          --docker-tag ${var.timekeeper-node-config.timekeeper-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4} \
          --sync-mode ${var.timekeeper-node-config.timekeeper-nodes[count.index].sync-mode} \
          --is-reserved ${var.timekeeper-node-config.timekeeper-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
