resource "aws_instance" "archive_node" {
  count             = 1
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.instance_type
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.gemini-squid-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.disk_volume_size
    volume_type = var.disk_volume_type
    iops = 3000
    throughput = 250
  }

  tags = {
    name       = "squid-archive"
    role       = "archive"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install git curl gnupg openssl net-tools -y",
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
    agent          = true
    agent_identity = var.aws_key_name
    private_key = file("${var.private_key_path}")
    timeout     = "180s"
  }

}
