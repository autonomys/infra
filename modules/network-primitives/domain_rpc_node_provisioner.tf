resource "null_resource" "setup_domain_rpc_nodes" {
  count      = length(aws_instance.domain_rpc_nodes)
  depends_on = [aws_instance.domain_rpc_nodes]

  connection {
    host           = aws_instance.domain_rpc_nodes[count.index].public_ip
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

  # copy LE script
  provisioner "file" {
    source      = "${var.path_to_scripts}/acme.sh"
    destination = "/home/${var.ssh_user}/subspace/acme.sh"
  }

  # install docker and docker compose and LE script
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo bash /home/${var.ssh_user}/subspace/installer.sh
      bash /home/${var.ssh_user}/subspace/acme.sh
      EOT
    ]
  }

}

resource "null_resource" "start_domain_rpc_nodes" {
  count      = length(aws_instance.domain_rpc_nodes)
  depends_on = [null_resource.setup_domain_rpc_nodes]

  # trigger node re-deployment on any of the following changes
  triggers = {
    domain-id            = var.domain-rpc-node-config.rpc-nodes[count.index].domain-id
    domain-name          = var.domain-rpc-node-config.rpc-nodes[count.index].domain-name
    docker-tag           = var.domain-rpc-node-config.rpc-nodes[count.index].docker-tag
    reserved-only        = var.domain-rpc-node-config.rpc-nodes[count.index].reserved-only
    index                = var.domain-rpc-node-config.rpc-nodes[count.index].index
    sync-mode            = var.domain-rpc-node-config.rpc-nodes[count.index].sync-mode
    eth-cache            = var.domain-rpc-node-config.rpc-nodes[count.index].eth-cache
    enable-reverse-proxy = var.domain-rpc-node-config.enable-reverse-proxy
    enable-load-balancer = var.domain-rpc-node-config.enable-load-balancer
  }

  connection {
    host           = aws_instance.domain_rpc_nodes[count.index].public_ip
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
      sudo hostnamectl set-hostname ${var.network_name}-domain-${var.domain-rpc-node-config.rpc-nodes[count.index].domain-id}-rpc-node-${var.domain-rpc-node-config.rpc-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest domain-rpc \
          --node-id ${var.domain-rpc-node-config.rpc-nodes[count.index].index} \
          --docker-tag ${var.domain-rpc-node-config.rpc-nodes[count.index].docker-tag} \
          --external-ip-v4 ${aws_instance.domain_rpc_nodes[count.index].public_ip} \
          --external-ip-v6 ${aws_instance.domain_rpc_nodes[count.index].ipv6_addresses[0]} \
          --node-prefix ${var.domain-rpc-node-config.rpc-nodes[count.index].domain-name} \
          --domain-id ${var.domain-rpc-node-config.rpc-nodes[count.index].domain-id} \
          --enable-reverse-proxy ${var.domain-rpc-node-config.enable-reverse-proxy} \
		  --enable-load-balancer ${var.domain-rpc-node-config.enable-load-balancer} \
          --sync-mode ${var.domain-rpc-node-config.rpc-nodes[count.index].sync-mode} \
          --eth-cache ${var.domain-rpc-node-config.rpc-nodes[count.index].eth-cache} \
          --is-reserved ${var.domain-rpc-node-config.rpc-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
