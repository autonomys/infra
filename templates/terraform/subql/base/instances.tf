resource "aws_instance" "subql_blue_node" {
  count             = length(var.aws_region) * var.blue-subql-node-config.instance-count-blue > 0 ? var.blue-subql-node-config.instance-count-blue : 0
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.blue-subql-node-config.instance-type
  subnet_id         = element(aws_subnet.public_subnets.*.id, 0)
  availability_zone = element(var.azs, 0)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.subql-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  ebs_optimized = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.blue-subql-node-config.disk-volume-size
    volume_type = var.blue-subql-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    name       = "subql-${var.blue-subql-node-config.network-name}"
    Name       = "${var.blue-subql-node-config.domain-prefix}-${var.blue-subql-node-config.network-name}"
    role       = "block explorer"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.subql-gw

  ]

  lifecycle {

    ignore_changes = [ami, instance_type]

  }

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo apt install git curl btop wget gnupg openssl net-tools git -y",

    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "180s"
  }

}


resource "aws_instance" "subql_green_node" {
  count             = length(var.aws_region) * var.green-subql-node-config.instance-count-green > 0 ? var.green-subql-node-config.instance-count-green : 0
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.green-subql-node-config.instance-type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.subql-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  ebs_optimized = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.green-subql-node-config.disk-volume-size
    volume_type = var.green-subql-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    name       = "subql-${var.green-subql-node-config.network-name}"
    Name       = "${var.green-subql-node-config.domain-prefix}-${var.green-subql-node-config.network-name}"
    role       = "block explorer"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.subql-gw
  ]

  lifecycle {

    ignore_changes = [ami, instance_type]

  }

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt install git curl btop wget gnupg openssl net-tools git -y",

    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "180s"
  }

}

resource "aws_instance" "nova_subql_blue_node" {
  count             = length(var.aws_region) * var.nova-blue-subql-node-config.instance-count-blue > 0 ? var.nova-blue-subql-node-config.instance-count-blue : 0
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.nova-blue-subql-node-config.instance-type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.subql-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  ebs_optimized = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.nova-blue-subql-node-config.disk-volume-size
    volume_type = var.nova-blue-subql-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    name       = "subql-${var.nova-blue-subql-node-config.network-name}"
    Name       = "${var.nova-blue-subql-node-config.domain-prefix}-subql-${var.nova-blue-subql-node-config.network-name}"
    role       = "block explorer"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.subql-gw
  ]

  lifecycle {

    ignore_changes = [ami, instance_type]

  }

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt install git curl btop wget gnupg openssl net-tools git -y",

    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "180s"
  }

}

resource "aws_instance" "nova_subql_green_node" {
  count             = length(var.aws_region) * var.nova-green-subql-node-config.instance-count-green > 0 ? var.nova-green-subql-node-config.instance-count-green : 0
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.nova-green-subql-node-config.instance-type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.subql-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  ebs_optimized = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.nova-green-subql-node-config.disk-volume-size
    volume_type = var.nova-green-subql-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    name       = "subql-${var.nova-green-subql-node-config.network-name}"
    Name       = "${var.nova-green-subql-node-config.domain-prefix}-subql-${var.nova-green-subql-node-config.network-name}"
    role       = "block explorer"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.subql-gw
  ]

  lifecycle {

    ignore_changes = [ami, instance_type]

  }

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt install git curl btop wget gnupg openssl net-tools git -y",

    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = var.ssh_user
    private_key = file("${var.private_key_path}")
    timeout     = "180s"
  }

}
