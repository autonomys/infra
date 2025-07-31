resource "null_resource" "setup-domain-bootstrap-nodes" {
  count      = length(aws_instance.domain_bootstrap_nodes)
  depends_on = [aws_instance.domain_bootstrap_nodes]

  connection {
    host           = aws_instance.domain_bootstrap_nodes[count.index].public_ip
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

resource "null_resource" "start-domain-bootstrap-nodes" {
  count      = length(aws_instance.domain_bootstrap_nodes)
  depends_on = [null_resource.setup-domain-bootstrap-nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.domain-bootstrap-node-config.deployment-version
  }

  connection {
    host           = aws_instance.domain_bootstrap_nodes[count.index].public_ip
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
      sudo hostnamectl set-hostname ${var.network_name}-domain-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id}-bootstrap-node-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data vedhavyas/node-utils:latest domain-bootstrap \
          --node-id ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].index} \
          --docker-tag ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].docker-tag} \
          --external-ip-v4 ${aws_instance.domain_bootstrap_nodes[count.index].public_ip} \
          --external-ip-v6 ${aws_instance.domain_bootstrap_nodes[count.index].ipv6_addresses[0]} \
          --node-prefix ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-name} \
          --domain-id ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id} \
          --sync-mode ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].sync-mode} \
          --is-reserved ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
