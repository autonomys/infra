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

  lifecycle { ignore_changes = [ami] }

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

  lifecycle { ignore_changes = [ami] }
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

  lifecycle { ignore_changes = [ami] }

}

resource "aws_instance" "domain_bootstrap_nodes" {
  count                       = var.domain-bootstrap-node-config == null ? 0 : length(var.domain-bootstrap-node-config.bootstrap-nodes)
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
    Name       = "${var.network_name}-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-name}-bootstrap-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].index}"
    role       = "Domain bootstrap node"
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

resource "aws_instance" "domain_rpc_nodes" {
  count                       = var.domain-rpc-node-config == null ? 0 : length(var.domain-rpc-node-config.rpc-nodes)
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
    Name       = "${var.network_name}-${var.domain-rpc-node-config.rpc-nodes[count.index].domain-name}-rpc-${var.domain-rpc-node-config.rpc-nodes[count.index].index}"
    role       = "Domain RPC node"
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

resource "aws_instance" "domain_operator_nodes" {
  count                       = var.domain-operator-node-config == null ? 0 : length(var.domain-operator-node-config.operator-nodes)
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
    Name       = "${var.network_name}-${var.domain-operator-node-config.operator-nodes[count.index].domain-name}-operator-${var.domain-operator-node-config.operator-nodes[count.index].index}"
    role       = "Domain Operator node"
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
