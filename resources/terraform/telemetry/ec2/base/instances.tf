resource "aws_instance" "telemetry_subspace_node" {
  ami               = data.aws_ami.ubuntu_amd64.image_id
  instance_type     = var.instance_type
  subnet_id         = aws_subnet.public_subnets.id
  availability_zone = var.azs
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.telemetry-subspace-sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.telemetry-subspace-node-config.disk-volume-size
    volume_type = var.telemetry-subspace-node-config.disk-volume-type
    iops = 3000
    throughput = 250
  }

  tags = {
    name       = "telemetry-subspace-node"
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

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    agent       = true
    private_key = file("${var.private_key_path}")
    timeout     = "90s"
  }

}
