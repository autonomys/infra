resource "null_resource" "setup_consensus_farmer_nodes" {
  count      = length(aws_instance.consensus_farmer_nodes)
  depends_on = [aws_instance.consensus_farmer_nodes]

  connection {
    host           = aws_instance.consensus_farmer_nodes[count.index].public_ip
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # init node
  # farmer node should have an nvme based local instance store
  # we cannot use EBS here since proving timeouts with EBS
  # TODO: currently assumes nvme1n1 drive name but ideally
  #  we should use nvme-cli to get the correct drive and
  #  and then mount it instead
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      cloud-init status --wait
      sudo apt update -y
      sudo mkfs -t ext4 /dev/nvme1n1
      sudo mkdir /subspace_data
      sudo mount /dev/nvme1n1 /subspace_data
      sudo mkdir -p /home/${var.ssh_user}/subspace/
      sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.ssh_user}/subspace/
      sudo mkdir -p /subspace_data/node/
      sudo mkdir -p /subspace_data/farmer/
      sudo chown -R nobody:nogroup /subspace_data
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

resource "null_resource" "start_consensus_farmer_nodes" {
  count      = length(aws_instance.consensus_farmer_nodes)
  depends_on = [null_resource.setup_consensus_farmer_nodes]

  # trigger node deployment if node details change
  triggers = var.farmer-node-config.farmer-nodes[count.index]

  connection {
    host           = aws_instance.consensus_farmer_nodes[count.index].public_ip
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
      sudo hostnamectl set-hostname ${var.network_name}-farmer-node-${var.farmer-node-config.farmer-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest farmer \
          --node-id ${var.farmer-node-config.farmer-nodes[count.index].index} \
          --docker-tag ${var.farmer-node-config.farmer-nodes[count.index].docker-tag} \
          --external-ip-v4 ${aws_instance.consensus_farmer_nodes[count.index].public_ip} \
          --external-ip-v6 ${aws_instance.consensus_farmer_nodes[count.index].ipv6_addresses[0]} \
          --plot-size ${var.farmer-node-config.farmer-nodes[count.index].plot-size} \
          --reward-address ${var.farmer-node-config.farmer-nodes[count.index].reward-address} \
          --cache-percentage ${var.farmer-node-config.farmer-nodes[count.index].cache-percentage} \
          --faster-sector-plotting ${var.farmer-node-config.farmer-nodes[count.index].faster-sector-plotting} \
          --force-block-production ${var.farmer-node-config.farmer-nodes[count.index].force-block-production} \
          --sync-mode ${var.farmer-node-config.farmer-nodes[count.index].sync-mode} \
          --is-timekeeper ${var.farmer-node-config.farmer-nodes[count.index].is-timekeeper} \
          --is-reserved ${var.farmer-node-config.farmer-nodes[count.index].reserved-only}

      # start subspace
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
