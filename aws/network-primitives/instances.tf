resource "aws_instance" "bootstrap_node" {
  count             = length(var.aws_region) * var.bootstrap-node-config.instance-count
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.instance_type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.network_sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.bootstrap-node-config.disk-volume-size
    volume_type = var.bootstrap-node-config.disk-volume-type
    iops = 3000
    throughput = 250
  }


  tags = {
    name       = "${var.network_name}-bootstrap"
    role       = "bootstrap node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install curl gnupg openssl net-tools -y",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

}


resource "aws_instance" "full_node" {
  count             = length(var.aws_region) * var.full-node-config.instance-count
  ami               = data.aws_ami.ubuntu_amd64.image_id
  # instance_type     = var.instance_type
  instance_type     = "t3.small"
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.network_sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.full-node-config.disk-volume-size
    volume_type = var.full-node-config.disk-volume-type
    iops = 3000
    throughput = 250
  }

  tags = {
    name       = "${var.network_name}-full"
    role       = "full node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install curl gnupg openssl net-tools -y",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

}


resource "aws_instance" "rpc_node" {
  count             = length(var.aws_region) * var.rpc-node-config.instance-count
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.instance_type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.network_sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.rpc-node-config.disk-volume-size
    volume_type = var.rpc-node-config.disk-volume-type
    iops = 3000
    throughput = 250
  }
  tags = {
    name       = "${var.network_name}-rpc"
    role       = "rpc node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install curl gnupg openssl net-tools -y",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

}


resource "aws_instance" "domain_node" {
  count             = length(var.aws_region) * var.domain-node-config.instance-count
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.instance_type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.network_sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.domain-node-config.disk-volume-size
    volume_type = var.domain-node-config.disk-volume-type
    iops = 3000
    throughput = 250
  }

  tags = {
    name       = "${var.network_name}-domain"
    role       = "domain node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install curl gnupg openssl net-tools -y",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

}


resource "aws_instance" "farmer_node" {
  count             = length(var.aws_region) * var.farmer-node-config.instance-count
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.instance_type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.network_sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.farmer-node-config.disk-volume-size
    volume_type = var.farmer-node-config.disk-volume-type
    iops = 3000
    throughput = 250
  }
  tags = {
    name       = "${var.network_name}-farmer"
    role       = "farmer node"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install curl gnupg openssl net-tools -y",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "300s"
  }

}
