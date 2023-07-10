resource "aws_instance" "squid_blue_node" {
  count             = length(var.aws_region) * var.blue-squid-node-config.instance-count-blue
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.blue-squid-node-config.instance-type
  subnet_id         = element(aws_subnet.public_subnets.*.id, 0)
  availability_zone = element(var.azs, 0)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.gemini-squid-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  ebs_optimized = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.blue-squid-node-config.disk-volume-size
    volume_type = var.blue-squid-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    name       = "squid-${var.blue-squid-node-config.network-name}"
    role       = "block explorer"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.squid-gw
  ]

  lifecycle {

    prevent_destroy = true

  }

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install wget gnupg openssl net-tools -y",
      # install monitoring
      "sudo wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud",

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


resource "aws_instance" "squid_green_node" {
  count             = length(var.aws_region) * var.green-squid-node-config.instance-count-green
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.green-squid-node-config.instance-type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.gemini-squid-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  ebs_optimized = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.green-squid-node-config.disk-volume-size
    volume_type = var.green-squid-node-config.disk-volume-type
    iops        = 3000
    throughput  = 250
  }

  tags = {
    name       = "squid-${var.green-squid-node-config.network-name}"
    role       = "block explorer"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.squid-gw
  ]

  lifecycle {

    prevent_destroy = true

  }

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt install git curl wget gnupg openssl net-tools -y",
      # install monitoring
      "sudo wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud",

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
