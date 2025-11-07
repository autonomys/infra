resource "aws_instance" "chain_alert_node" {
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.instance.instance_type
  subnet_id                   = aws_subnet.public_subnets.id
  availability_zone           = var.aws.availability_zone
  region                      = var.aws.region
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws.ssh_key_name
  associate_public_ip_address = true
  ipv6_address_count          = 1

  tags = {
    Name       = "${var.instance.network_name}-chain-alerts"
    role       = "Chain Alerts"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  lifecycle { ignore_changes = [ami] }
}

resource "null_resource" "setup_chain_alert_node" {
  depends_on = [aws_instance.chain_alert_node]

  connection {
    host           = aws_instance.chain_alert_node.public_ip
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # init node
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      cloud-init status --wait
      sudo apt update -y
      sudo mkdir -p /home/${var.deployer.ssh_user}/subspace/
      sudo chown -R ${var.deployer.ssh_user}:${var.deployer.ssh_user} /home/${var.deployer.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.deployer.ssh_user}/subspace/
      EOT
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/installer.sh"
    destination = "/home/${var.deployer.ssh_user}/subspace/installer.sh"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo bash /home/${var.deployer.ssh_user}/subspace/installer.sh
      EOT
    ]
  }

}

resource "null_resource" "start_chain_alert_node" {
  depends_on = [null_resource.setup_chain_alert_node]

  # trigger node re-deployment if anything changes in the node config
  triggers = var.instance

  connection {
    host           = aws_instance.chain_alert_node.public_ip
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # copy docker compose file
  provisioner "file" {
    source      = var.deployer.path_to_docker_compose
    destination = "/home/${var.deployer.ssh_user}/subspace/docker-compose.yml"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # stop any running service
      sudo docker compose -f /home/${var.deployer.ssh_user}/subspace/docker-compose.yml down

      # set hostname
      sudo hostnamectl set-hostname ${var.instance.network_name}-chain-alerts

      # create slack secret and set permission
	  sudo echo "${var.instance.slack_secret}" > /home/${var.deployer.ssh_user}/subspace/slack-secret
      sudo chmod 400 /home/${var.deployer.ssh_user}/subspace/slack-secret
      sudo chown nobody:nogroup /home/${var.deployer.ssh_user}/subspace/slack-secret

      # create .env file
      sudo echo "DOCKER_TAG=${var.instance.docker_tag}" > /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "SLACK_SECRET_PATH=/home/${var.deployer.ssh_user}/subspace/slack-secret" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "RPC_NODE_URL=${var.instance.rpc_url}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "ALERTER_NAME=${title(var.instance.network_name)}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "UPTIMEKUMA_URL=${var.instance.uptimekuma_url}" >> /home/${var.deployer.ssh_user}/subspace/.env

      # start subspace node
      sudo docker compose -f /home/${var.deployer.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
