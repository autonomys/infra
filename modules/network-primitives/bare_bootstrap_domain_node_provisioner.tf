resource "null_resource" "setup-bare-domain-bootstrap-nodes" {
  count = var.bare-domain-bootstrap-node-config == null ? 0 : length(var.bare-domain-bootstrap-node-config.bootstrap-nodes)

  connection {
    host           = var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].ipv4
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

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo bash /home/${var.ssh_user}/subspace/installer.sh
      EOT
    ]
  }

}

resource "null_resource" "start-bare-domain-bootstrap-nodes" {
  count      = var.bare-domain-bootstrap-node-config == null ? 0 : length(var.bare-domain-bootstrap-node-config.bootstrap-nodes)
  depends_on = [null_resource.setup-bare-domain-bootstrap-nodes]

  # trigger node deployment of the node object changes
  triggers = var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index]

  connection {
    host           = var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].ipv4
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
      sudo hostnamectl set-hostname ${var.network_name}-domain-${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id}-bootstrap-node-${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest domain-bootstrap \
          --network ${var.network_name} \
          --fqdn ${var.cloudflare_domain_fqdn} \
          --node-id ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].index} \
          --docker-tag ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].ipv4} \
          --node-prefix ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-name} \
          --domain-id ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-id} \
          --sync-mode ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].sync-mode} \
          --is-reserved ${var.bare-domain-bootstrap-node-config.bootstrap-nodes[count.index].reserved-only}

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
