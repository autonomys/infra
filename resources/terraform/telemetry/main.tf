module "telemetry_subspace_node" {
  source = "../../../templates/terraform/aws/ec2"

  ami                         = data.aws_ami.ubuntu_amd64.image_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnets.id
  availability_zone           = var.azs
  vpc_security_group_ids      = ["${aws_security_group.telemetry-subspace-sg.id}"]
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  ebs_optimized               = true
  root_block_device = [
    {
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      volume_size           = var.disk_volume_size
      volume_type           = var.disk_volume_type
      throughput            = 250
      tags = {
        Name = "telemetry-root-volume"
      }
    }
  ]

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
}
