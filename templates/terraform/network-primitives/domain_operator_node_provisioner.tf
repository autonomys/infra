locals {
  domain_operator_nodes_ipv4 = flatten([[aws_instance.domain_operator_nodes.*.public_ip]])
  domain_operator_nodes_ipv6 = flatten([[aws_instance.domain_operator_nodes.*.ipv6_addresses]])
}

resource "null_resource" "setup_domain_operator_nodes" {
  count = length(local.domain_operator_nodes_ipv4)

  depends_on = [aws_instance.domain_operator_nodes]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.domain_operator_nodes_ipv4)
  }

  connection {
    host           = local.domain_operator_nodes_ipv4[count.index]
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

  # install docker and docker compose and LE script
  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/${var.ssh_user}/subspace/installer.sh",
    ]
  }

}

resource "null_resource" "start_domain_operator_nodes" {
  count = length(local.domain_operator_nodes_ipv4)

  depends_on = [null_resource.setup_domain_operator_nodes]

  # trigger on node deployment version change
  triggers = {
    deployment_version = var.domain-operator-node-config.deployment-version
  }

  connection {
    host           = local.domain_operator_nodes_ipv4[count.index]
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
      "sudo hostnamectl set-hostname ${var.network_name}-domain-${local.domain_operator_nodes_list[count.index].domain-id}-operator-node-${count.index}",

      # create docker compose
      "sudo docker run --pull always -v /home/${var.ssh_user}/subspace:/data vedhavyas/node-utils:latest domain-operator " +
      "--node-id ${local.domain_operator_nodes_list[count.index].index} " +
      "--docker-tag ${local.domain_operator_nodes_list[count.index].docker-tag} " +
      "--external-ip-v4 ${local.domain_operator_nodes_ipv4[count.index]} " +
      "--external-ip-v6 ${local.domain_operator_nodes_ipv6[count.index]} " +
      "--node-prefix ${local.domain_operator_nodes_list[count.index].domain-name} " +
      "--domain-id ${local.domain_operator_nodes_list[count.index].domain-id} " +
      "--domain-id ${local.domain_operator_nodes_list[count.index].operator-id} " +
      "--is-reserved ${local.domain_operator_nodes_list[count.index].reserved-only} ",

      # start subspace node
      "sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d",

      # wait until container is created
      "sudo sh -c 'until docker ps -f \"name=subspace-node-1\" --format \"{{.ID}}\" | grep -q .; do sleep 1; done'",

      # insert domain operator key
      # TODO
      #"sudo docker cp /home/${var.ssh_user}/subspace/domains/${var.auto-evm-domain-node-config.domain-id}/keystore/. subspace-archival-node-1:/var/subspace/domains/${var.auto-evm-domain-node-config.domain-id}/keystore/"
    ]
  }
}
