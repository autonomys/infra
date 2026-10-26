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

  # trigger node re-deployment if the node config or its external IP changes
  triggers = merge(var.domain-bootstrap-node-config.bootstrap-nodes[count.index], {
    external-ip = aws_instance.domain_bootstrap_nodes[count.index].public_ip
  })

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
      set -e
      trap 'sudo rm -f /home/${var.ssh_user}/subspace/config.toml' EXIT
      trap 'exit 1' HUP INT TERM

      # set hostname
      sudo hostnamectl set-hostname ${var.network_name}-domain-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id}-bootstrap-node-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest domain-bootstrap \
          --network ${var.network_name} \
          --fqdn ${var.cloudflare_domain_fqdn} \
          --node-id ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].index} \
          --docker-tag ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].docker-tag} \
          --external-ip-v4 ${aws_instance.domain_bootstrap_nodes[count.index].public_ip} \
          --external-ip-v6 ${aws_instance.domain_bootstrap_nodes[count.index].ipv6_addresses[0]} \
          --node-prefix ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-name} \
          --domain-id ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id} \
          --sync-mode ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].sync-mode} \
          --is-reserved ${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].reserved-only}

      # pull before anything stops, so a failed pull leaves the running node untouched
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml pull node

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d --remove-orphans

      # a node that is not running, or restarts within 30s, fails the apply before old images are pruned
      i=0
      until [ "$(sudo docker inspect --type container -f '{{.State.Status}}' node 2>/dev/null)" = running ]; do
        i=$((i+1))
        if [ "$i" -ge 300 ]; then echo "node container not running after 300s" >&2; exit 1; fi
        sleep 1
      done
      restarts=$(sudo docker inspect --type container -f '{{.RestartCount}}' node)
      sleep 30
      if [ "$(sudo docker inspect --type container -f '{{.State.Status}} {{.RestartCount}}' node)" != "running $restarts" ]; then
        echo "node container restarted or stopped within 30s of starting" >&2; exit 1
      fi

      # drop images left by previous deploys; the running one is protected
      sudo docker image prune -af
      EOT
    ]
  }
}
