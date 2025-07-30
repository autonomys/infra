resource "aws_instance" "consensus_bootstrap_nodes" {
  count                       = var.consensus-bootstrap-node-config == null ? 0 : length(var.consensus-bootstrap-node-config.bootstrap-nodes)
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.consensus-bootstrap-node-config.instance-type
  subnet_id                   = aws_subnet.public_subnets.*.id[0]
  availability_zone           = var.availability_zone
  region                      = var.aws_region
  ipv6_address_count          = 1
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws_ssh_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.consensus-bootstrap-node-config.disk-volume-size
    volume_type = var.consensus-bootstrap-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }


  tags = {
    Name       = "${var.network_name}-consensus-bootstrap-${var.consensus-bootstrap-node-config.bootstrap-nodes[count.index].index}"
    role       = "Consensus Bootstrap node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  # lifecycle {
  #   ignore_changes = [ami, ipv6_address_count, associate_public_ip_address]
  # }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update -y",
    ]

    on_failure = continue
  }

  # Setting up the ssh connection
  connection {
    type           = "ssh"
    host           = self.*.public_ip[count.index]
    user           = var.ssh_user
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }
}

resource "aws_instance" "consensus_rpc_nodes" {
  count                       = var.consensus-rpc-node-config == null ? 0 : length(var.consensus-rpc-node-config.rpc-nodes)
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.consensus-rpc-node-config.instance-type
  subnet_id                   = aws_subnet.public_subnets.*.id[0]
  region                      = var.aws_region
  availability_zone           = var.availability_zone
  ipv6_address_count          = 1
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws_ssh_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.consensus-rpc-node-config.disk-volume-size
    volume_type = var.consensus-rpc-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }
  tags = {
    Name       = "${var.network_name}-consensus-rpc-${var.consensus-rpc-node-config.rpc-nodes[count.index].index}"
    role       = "Consensus Rpc node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  # lifecycle {
  #   ignore_changes = [ami, ipv6_address_count, associate_public_ip_address]
  # }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install curl gnupg openssl net-tools -y",
    ]

    on_failure = continue
  }

  # Setting up the ssh connection
  connection {
    type           = "ssh"
    host           = self.*.public_ip[count.index]
    user           = var.ssh_user
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }
}

resource "aws_instance" "consensus_farmer_nodes" {
  count                       = var.farmer-node-config == null ? 0 : length(var.farmer-node-config.farmer-nodes)
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.farmer-node-config.instance-type
  subnet_id                   = aws_subnet.public_subnets.*.id[0]
  region                      = var.aws_region
  availability_zone           = var.availability_zone
  ipv6_address_count          = 1
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws_ssh_key_name
  associate_public_ip_address = true
  tags = {
    Name       = "${var.network_name}-consensus-farmer-${var.farmer-node-config.farmer-nodes[count.index].index}"
    role       = "Consensus Farmer node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  # lifecycle {
  #   ignore_changes = [ami, ipv6_address_count, associate_public_ip_address]
  # }

  // farmer node should have an nvme based local instance store
  // we cannot use EBS here since proving timeouts with EBS
  // TODO: currently assumes nvme1n1 drive name but ideally
  //  we should use nvme-cli to get the correct drive and
  //  and then mount it instead
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update -y",
      "sudo mkfs -t ext4 /dev/nvme1n1",
      "sudo mkdir /subspace_data",
      "sudo mount /dev/nvme1n1 /subspace_data",
    ]

    on_failure = continue
  }

  # Setting up the ssh connection
  connection {
    type           = "ssh"
    host           = self.*.public_ip[count.index]
    user           = var.ssh_user
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }
}

locals {
  domain_bootstrap_nodes_list = var.domain-bootstrap-node-config != null ? flatten([
    for domain in var.domain-bootstrap-node-config.domains : [
      for bootstrap_node in domain.bootstrap-nodes : {
        domain-id     = domain.domain-id
        domain-name   = domain.domain-name
        docker-tag    = bootstrap_node.docker-tag
        reserved-only = bootstrap_node.reserved-only
        index         = bootstrap_node.index
      }
    ]
  ]) : []
}

resource "aws_instance" "domain_bootstrap_nodes" {
  count                       = length(local.domain_bootstrap_nodes_list)
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.domain-bootstrap-node-config.instance-type
  subnet_id                   = aws_subnet.public_subnets.*.id[0]
  region                      = var.aws_region
  availability_zone           = var.availability_zone
  ipv6_address_count          = 1
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws_ssh_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.domain-bootstrap-node-config.disk-volume-size
    volume_type = var.domain-bootstrap-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    Name       = "${var.network_name}-${local.domain_bootstrap_nodes_list[count.index].domain-name}-bootstrap-${local.domain_bootstrap_nodes_list[count.index].index}"
    role       = "Domain bootstrap node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  # lifecycle {
  #   ignore_changes = [ami, ipv6_address_count, associate_public_ip_address]
  # }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update -y",
    ]

    on_failure = continue
  }

  # Setting up the ssh connection
  connection {
    type           = "ssh"
    host           = self.*.public_ip[count.index]
    user           = var.ssh_user
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }
}

locals {
  domain_rpc_nodes_list = var.domain-rpc-node-config != null ? flatten([
    for domain in var.domain-rpc-node-config.domains : [
      for rpc_node in domain.rpc-nodes : {
        domain-id     = domain.domain-id
        domain-name   = domain.domain-name
        docker-tag    = rpc_node.docker-tag
        reserved-only = rpc_node.reserved-only
        index         = rpc_node.index
      }
    ]
  ]) : []
}

resource "aws_instance" "domain_rpc_nodes" {
  count                       = length(local.domain_rpc_nodes_list)
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.domain-rpc-node-config.instance-type
  subnet_id                   = aws_subnet.public_subnets.*.id[0]
  region                      = var.aws_region
  availability_zone           = var.availability_zone
  ipv6_address_count          = 1
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws_ssh_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.domain-rpc-node-config.disk-volume-size
    volume_type = var.domain-rpc-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    Name       = "${var.network_name}-${local.domain_rpc_nodes_list[count.index].domain-name}-rpc-${local.domain_rpc_nodes_list[count.index].index}"
    role       = "Domain RPC node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  # lifecycle {
  #   ignore_changes = [ami, ipv6_address_count, associate_public_ip_address]
  # }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update -y",
    ]

    on_failure = continue
  }

  # Setting up the ssh connection
  connection {
    type           = "ssh"
    host           = self.*.public_ip[count.index]
    user           = var.ssh_user
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }
}

locals {
  domain_operator_nodes_list = var.domain-operator-node-config != null ? flatten([
    for domain in var.domain-operator-node-config.domains : [
      for operator_node in domain.operator-nodes : {
        domain-id     = domain.domain-id
        domain-name   = domain.domain-name
        docker-tag    = operator_node.docker-tag
        reserved-only = operator_node.reserved-only
        operator-id   = operator_node.operator-id
        index         = operator_node.index
      }
    ]
  ]) : []
}

resource "aws_instance" "domain_operator_nodes" {
  count                       = length(local.domain_operator_nodes_list)
  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.domain-operator-node-config.instance-type
  subnet_id                   = aws_subnet.public_subnets.*.id[0]
  region                      = var.aws_region
  availability_zone           = var.availability_zone
  ipv6_address_count          = 1
  vpc_security_group_ids      = [aws_security_group.network_sg.id]
  key_name                    = var.aws_ssh_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.domain-operator-node-config.disk-volume-size
    volume_type = var.domain-operator-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    Name       = "${var.network_name}-${local.domain_operator_nodes_list[count.index].domain-name}-operator-${local.domain_operator_nodes_list[count.index].index}"
    role       = "Domain Operator node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  # lifecycle {
  #   ignore_changes = [ami, ipv6_address_count, associate_public_ip_address]
  # }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt update -y",
    ]

    on_failure = continue
  }

  # Setting up the ssh connection
  connection {
    type           = "ssh"
    host           = self.*.public_ip[count.index]
    user           = var.ssh_user
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }
}
