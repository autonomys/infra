resource "null_resource" "setup_bare_domain_operator_nodes" {
  count = length(var.bare-domain-operator-node-config.operator-nodes)

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
  count      = length(var.bare-domain-operator-node-config.operator-nodes)
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
  # TODO: use autonomys ghcr
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # stop any running service
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down

      # set hostname
      sudo hostnamectl set-hostname ${var.network_name}-domain-${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-id}-operator-node-${var.bare-domain-operator-node-config.operator-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data vedhavyas/node-utils:latest domain-operator \
          --node-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].index} \
          --docker-tag ${var.bare-domain-operator-node-config.operator-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.bare-domain-operator-node-config.operator-nodes[count.index].ipv4} \
          --node-prefix ${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-name} \
          --domain-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-id} \
          --operator-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].operator-id} \
          --sync-mode ${var.bare-domain-operator-node-config.operator-nodes[count.index].sync-mode} \
          --is-reserved ${var.bare-domain-operator-node-config.operator-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d

      # wait until container is created
      sudo sh -c 'until docker ps -f "name=node" --format "{{.ID}}" | grep -q .; do sleep 1; done'

      # insert domain operator key
      sudo docker exec node /subspace-node domain key insert --base-path=/var/subspace --domain-id ${var.bare-domain-operator-node-config.operator-nodes[count.index].domain-id} --keystore-suri "$(cat /home/${var.ssh_user}/subspace/node.key)"
      EOT
    ]
  }
}
