resource "aws_instance" "telemetry_subspace_node" {
  count             = length(var.aws_region) * var.instance_count
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = element(var.instance_type, 0)
  subnet_id         = aws_subnet.public_subnets[count.index].id
  availability_zone = var.azs
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.telemetry-subspace-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    name       = "${var.network_name}-telemetry-subspace-node-${count.index}"
    role       = "telemetry server"
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
      "sudo DEBIAN_FRONTEND=noninteractive apt install curl wget gnupg openssl -y",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = "ubuntu"
    agent          = true
    private_key = file("${var.private_key_path}")
    timeout     = "90s"
  }

}
