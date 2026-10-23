resource "null_resource" "setup_bare_domain_operator_nodes" {
  count = var.bare-domain-operator-node-config == null ? 0 : length(var.bare-domain-operator-node-config.operator-nodes)

  connection {
    host           = var.bare-domain-operator-node-config.operator-nodes[count.index].ipv4
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

resource "null_resource" "start_bare_domain_operator_nodes" {
  count      = var.bare-domain-operator-node-config == null ? 0 : length(var.bare-domain-operator-node-config.operator-nodes)
  depends_on = [null_resource.setup_bare_domain_operator_nodes]

  # trigger node deployment on node object change
  triggers = var.bare-domain-operator-node-config.operator-nodes[count.index]

  connection {
    host           = var.bare-domain-operator-node-config.operator-nodes[count.index].ipv4
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
      sudo hostnamectl set-hostname ${var.network_name}-domain-${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-id}-operator-node-${var.bare-domain-operator-node-config.operator-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest domain-operator \
          --network ${var.network_name} \
          --fqdn ${var.cloudflare_domain_fqdn} \
          --node-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].index} \
          --docker-tag ${var.bare-domain-operator-node-config.operator-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.bare-domain-operator-node-config.operator-nodes[count.index].ipv4} \
          --node-prefix ${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-name} \
          --domain-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-id} \
          --operator-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].operator-id} \
          --sync-mode ${var.bare-domain-operator-node-config.operator-nodes[count.index].sync-mode} \
          --is-reserved ${var.bare-domain-operator-node-config.operator-nodes[count.index].reserved-only}

      # an empty suri would insert the public dev key
      KEY=$(cat /home/${var.ssh_user}/subspace/node.key)
      if [ -z "$KEY" ]; then echo "node.key is empty" >&2; exit 1; fi

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

      # insert domain operator key
      sudo docker exec node /subspace-node domain key insert --base-path=/var/subspace --domain-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-id} --keystore-suri "$KEY"

      # drop images left by previous deploys; the running one is protected
      sudo docker image prune -af
      EOT
    ]
  }
}
