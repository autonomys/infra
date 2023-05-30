resource "aws_instance" "archive_node" {
  count             = 1
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = element(var.instance_type, 1)
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.gemini-explorer-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    name       = "squid-archive"
    role       = "archive"
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

  # # base installation
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install git curl wget gnupg openssl net-tools -y",
      # install monitoring
      "sudo wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud",

    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = "ubuntu"
    private_key = file("${var.public_key_path}")
    timeout     = "90s"
  }

}
