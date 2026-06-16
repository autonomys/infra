data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "telemetry" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  availability_zone           = var.availability_zone
  vpc_security_group_ids      = [aws_security_group.telemetry.id]
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true

  root_block_device {
    volume_size = var.disk_volume_size
    volume_type = var.disk_volume_type
    iops        = 3000
    throughput  = 125
  }

  tags = {
    Name       = "telemetry"
    name       = "telemetry-subspace-node"
    role       = "telemetry server"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
