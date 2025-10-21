resource "null_resource" "setup_bare_consensus_rpc_nodes" {
  count = var.bare-consensus-rpc-node-config == null ? 0 : length(var.bare-consensus-rpc-node-config.rpc-nodes)

  connection {
    host           = var.bare-consensus-rpc-node-config.rpc-nodes[count.index].ipv4
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
      sudo DEBIAN_FRONTEND=noninteractive apt-get install curl gnupg openssl net-tools -y
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

resource "null_resource" "start_bare_consensus_rpc_nodes" {
  count      = length(null_resource.setup_bare_consensus_rpc_nodes)
  depends_on = [null_resource.setup_bare_consensus_rpc_nodes]

  # trigger node re-deployment on any of the following changes
  triggers = {
    index                = var.bare-consensus-rpc-node-config.rpc-nodes[count.index].index
    docker-tag           = var.bare-consensus-rpc-node-config.rpc-nodes[count.index].docker-tag
    reserved-only        = var.bare-consensus-rpc-node-config.rpc-nodes[count.index].reserved-only
    sync-mode            = var.bare-consensus-rpc-node-config.rpc-nodes[count.index].sync-mode
    enable-reverse-proxy = var.bare-consensus-rpc-node-config.enable-reverse-proxy
    enable-load-balancer = var.bare-consensus-rpc-node-config.enable-load-balancer
  }

  connection {
    host           = var.bare-consensus-rpc-node-config.rpc-nodes[count.index].ipv4
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
      sudo hostnamectl set-hostname ${var.network_name}-rpc-node-${var.bare-consensus-rpc-node-config.rpc-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest rpc \
          --network ${var.network_name} \
          --new-relic-api-key ${var.new_relic_api_key} \
          --fqdn ${var.cloudflare_domain_fqdn} \
          --node-id ${var.bare-consensus-rpc-node-config.rpc-nodes[count.index].index} \
          --docker-tag ${var.bare-consensus-rpc-node-config.rpc-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.bare-consensus-rpc-node-config.rpc-nodes[count.index].ipv4} \
          --node-prefix ${var.bare-consensus-rpc-node-config.dns-prefix} \
          --enable-reverse-proxy ${var.bare-consensus-rpc-node-config.enable-reverse-proxy} \
          --enable-load-balancer ${var.bare-consensus-rpc-node-config.enable-load-balancer} \
          --cloudflare-dns-api-token ${var.cloudflare_api_token} \
          --sync-mode ${var.bare-consensus-rpc-node-config.rpc-nodes[count.index].sync-mode} \
          --is-reserved ${var.bare-consensus-rpc-node-config.rpc-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d

      # delete config file
      sudo rm -rf /home/${var.ssh_user}/subspace/config.toml
      EOT
    ]
  }
}
