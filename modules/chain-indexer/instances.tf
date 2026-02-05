resource "aws_instance" "chain_indexer_node" {
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.instance.instance_type
  subnet_id                   = aws_subnet.public_subnets.id
  availability_zone           = var.aws.availability_zone
  region                      = var.aws.region
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws.ssh_key_name
  associate_public_ip_address = true
  ipv6_address_count          = 1
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.instance.disk_volume_size
    volume_type = var.instance.disk_volume_type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    Name       = "${var.instance.network_name}-chain-indexer"
    role       = "Chain Indexer"
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

resource "null_resource" "setup_chain_indexer_node" {
  depends_on = [aws_instance.chain_indexer_node]

  connection {
    host           = aws_instance.chain_indexer_node.public_ip
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

resource "null_resource" "start_chain_indexer_node" {
  depends_on = [null_resource.setup_chain_indexer_node]

  # trigger node re-deployment if anything changes in the node config
  triggers = var.instance

  connection {
    host           = aws_instance.chain_indexer_node.public_ip
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

  # copy LE script
  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/acme.sh"
    destination = "/home/${var.deployer.ssh_user}/subspace/acme.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # stop any running service
      sudo docker compose -f /home/${var.deployer.ssh_user}/subspace/docker-compose.yml down

      # set hostname
      sudo hostnamectl set-hostname ${var.instance.network_name}-chain-indexer

      # install LE script
      bash /home/${var.deployer.ssh_user}/subspace/acme.sh

      # create .env file
      sudo echo "DOCKER_TAG=${var.instance.docker_tag}" > /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "DB_PASSWORD=${var.instance.db_password}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "CONSENSUS_RPC_URL=${var.instance.consensus_rpc}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "AUTO_EVM_RPC_URL=${var.instance.auto_evm_rpc}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "PROCESS_BLOCKS_IN_PARALLEL=${var.instance.process_blocks_in_parallel}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "CF_DNS_API_TOKEN=${var.cloudflare_api_token}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "NETWORK_NAME=${var.instance.network_name}" >> /home/${var.deployer.ssh_user}/subspace/.env
      sudo echo "DOMAIN=${var.instance.domain_fqdn}" >> /home/${var.deployer.ssh_user}/subspace/.env

      # start subspace node
      sudo docker compose -f /home/${var.deployer.ssh_user}/subspace/docker-compose.yml up -d
      EOT
    ]
  }
}
