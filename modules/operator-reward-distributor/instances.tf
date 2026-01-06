resource "aws_instance" "reward_distributor_node" {
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
    Name       = "${var.instance.network_name}-reward-distributor-node"
    role       = "Operator reward Distributor"
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

resource "null_resource" "setup_reward_distributor_node" {
  depends_on = [aws_instance.reward_distributor_node]

  connection {
    host           = aws_instance.reward_distributor_node.public_ip
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

resource "null_resource" "start_reward_distributor_node" {
  depends_on = [null_resource.setup_reward_distributor_node]

  # trigger node re-deployment if anything changes in the node config
  triggers = var.instance

  connection {
    host           = aws_instance.reward_distributor_node.public_ip
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

  # copy nginx conf
  provisioner "file" {
    source      = var.deployer.path_to_nginx_conf
    destination = "/home/${var.deployer.ssh_user}/subspace/nginx.conf"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # stop any running service
      sudo docker compose -f /home/${var.deployer.ssh_user}/subspace/docker-compose.yml down

      # set hostname
      sudo hostnamectl set-hostname ${var.instance.network_name}-reward-distributor

      # create .env file
      sudo echo "DOCKER_TAG=${var.instance.docker_tag}" > /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "CHAIN_WS=${var.instance.rpc_url}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "CHAIN_ID=${var.instance.network_name}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "INTERVAL_SECONDS=${var.instance.interval_seconds}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "TIP_AI3=${var.instance.tip_ai3}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "DAILY_CAP_AI3=${var.instance.daily_ai3_cap}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "MAX_RETRIES=${var.instance.max_retries}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "MORTALITY_BLOCKS=${var.instance.mortality_blocks}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "CONFIRMATIONS=${var.instance.confirmation_blocks}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "ACCOUNT_PRIVATE_KEY=${var.instance.account_private_key}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "DB_URL=sqlite:/data/ord.sqlite" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "HOST_DATA_DIR=/home/${var.deployer.ssh_user}/subspace/data" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "CONF_DIR=/home/${var.deployer.ssh_user}/subspace" >> /home/${var.deployer.ssh_user}/subspace/.env

      # start docker service
      sudo docker compose -f /home/${var.deployer.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
