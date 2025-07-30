locals {
  farmer_nodes_ipv4 = flatten([[aws_instance.consensus_farmer_nodes.*.public_ip]])
  farmer_nodes_ipv6 = flatten([[aws_instance.consensus_farmer_nodes.*.ipv6_addresses]])
}

resource "null_resource" "setup_consensus_farmer_nodes" {
  count = length(local.farmer_nodes_ipv4)

  depends_on = [aws_instance.consensus_farmer_nodes]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.farmer_nodes_ipv4)
  }

  connection {
    host           = local.farmer_nodes_ipv4[count.index]
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
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.ssh_user}/subspace/",
      "sudo mkdir -p /subspace_data/node/",
      "sudo mkdir -p /subspace_data/farmer/",
      "sudo chown -R nobody:nogroup /subspace_data",
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

resource "null_resource" "start_consensus_farmer_nodes" {
  count = length(local.farmer_nodes_ipv4)

  depends_on = [null_resource.setup_consensus_farmer_nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.farmer-node-config.deployment-version
  }

  connection {
    host           = local.farmer_nodes_ipv4[count.index]
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
      "sudo hostnamectl set-hostname ${var.network_name}-farmer-node-${var.farmer-node-config.farmer-nodes[count.index].index}",

      # create docker compose
      "sudo docker run --pull always -v /home/${var.ssh_user}/subspace:/data vedhavyas/node-utils:latest farmer " +
      "--node-id ${var.farmer-node-config.farmer-nodes[count.index].index} " +
      "--docker-tag ${var.farmer-node-config.farmer-nodes[count.index].docker-tag} " +
      "--external-ip-v4 ${local.farmer_nodes_ipv4[count.index]} " +
      "--external-ip-v6 ${local.farmer_nodes_ipv6[count.index]} " +
      "--plot-size ${var.farmer-node-config.farmer-nodes[count.index].plot-size} " +
      "--reward-address ${var.farmer-node-config.farmer-nodes[count.index].reward-address} " +
      "--cache-percentage ${var.farmer-node-config.farmer-nodes[count.index].cache-percentage} " +
      "--faster-sector-plotting ${var.farmer-node-config.farmer-nodes[count.index].faster-sector-plotting} " +
      "--force-block-production ${var.farmer-node-config.farmer-nodes[count.index].force-block-production} " +
      "--sync-mode ${var.farmer-node-config.farmer-nodes[count.index].sync-mode} " +
      "--is-reserved ${var.farmer-node-config.farmer-nodes[count.index].reserved-only} ",

      # start subspace
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",
    ]
  }
}
