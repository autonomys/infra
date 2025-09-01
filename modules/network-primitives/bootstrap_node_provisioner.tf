resource "null_resource" "setup-consensus-bootstrap-nodes" {
  count      = length(aws_instance.consensus_bootstrap_nodes)
  depends_on = [aws_instance.consensus_bootstrap_nodes]

  connection {
    host           = aws_instance.consensus_bootstrap_nodes[count.index].public_ip
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
      cloud-init status --wait
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

resource "null_resource" "start-consensus-boostrap-nodes" {
  count      = length(aws_instance.consensus_bootstrap_nodes)
  depends_on = [null_resource.setup-consensus-bootstrap-nodes]

  # trigger node re-deployment if anything changes in the node config
  triggers = var.consensus-bootstrap-node-config.bootstrap-nodes[count.index]

  connection {
    host           = aws_instance.consensus_bootstrap_nodes[count.index].public_ip
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
      sudo hostnamectl set-hostname ${var.network_name}-bootstrap-node-${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest bootstrap \
            --node-id ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].index} \
            --docker-tag ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].docker-tag} \
            --external-ip-v4 ${aws_instance.consensus_bootstrap_nodes[count.index].public_ip} \
            --external-ip-v6 ${aws_instance.consensus_bootstrap_nodes[count.index].ipv6_addresses[0]} \
            --sync-mode ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].sync-mode} \
            --is-reserved ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
