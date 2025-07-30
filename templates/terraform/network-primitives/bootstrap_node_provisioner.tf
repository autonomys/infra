locals {
  bootstrap_nodes_ip_v4 = flatten([[aws_instance.consensus_bootstrap_nodes.*.public_ip]])
  bootstrap_nodes_ip_v6 = flatten([[aws_instance.consensus_bootstrap_nodes.*.ipv6_addresses]])
}

resource "null_resource" "setup-consensus-bootstrap-nodes" {
  count      = length(local.bootstrap_nodes_ip_v4)
  depends_on = [aws_instance.consensus_bootstrap_nodes]
  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.bootstrap_nodes_ip_v4)
  }

  connection {
    host           = local.bootstrap_nodes_ip_v4[count.index]
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/${var.ssh_user}/subspace/",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.ssh_user}/subspace/"
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
      "sudo bash /home/${var.ssh_user}/subspace/installer.sh",
    ]
  }

}

resource "null_resource" "start-consensus-boostrap-nodes" {
  count      = length(local.bootstrap_nodes_ip_v4)
  depends_on = [null_resource.setup-consensus-bootstrap-nodes]
  # trigger on node deployment version change
  triggers = {
    deployment_version = var.consensus-bootstrap-node-config.deployment-version
  }

  connection {
    host           = local.bootstrap_nodes_ip_v4[count.index]
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
      # stop any running service
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down ",

      # set hostname
      "sudo hostnamectl set-hostname ${var.network_name}-bootstrap-node-${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].index}",

      # create docker compose
      "sudo docker run --pull always -v /home/${var.ssh_user}/subspace:/data vedhavyas/node-utils:latest bootstrap " +
      "--node-id ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].index} " +
      "--docker-tag ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].docker-tag} " +
      "--external-ip-v4 ${local.bootstrap_nodes_ip_v4[count.index]} " +
      "--external-ip-v6 ${local.bootstrap_nodes_ip_v6[count.index]} " +
      "--sync-mode ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].sync-mode} " +
      "--is-reserved ${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].reserved-only} ",

      # start subspace node
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",
    ]
  }
}
