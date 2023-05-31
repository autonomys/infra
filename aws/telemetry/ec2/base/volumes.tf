# Create EBS volumes
resource "aws_ebs_volume" "telemetry_subspace_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = var.azs

  size = var.disk_volume_size # volume size (in GB)
  type = var.disk_volume_type # volume type

  tags = {
    Name = "telemetry_subspace_node_volume_${count.index}"
  }
}

# Attach the EBS volumes to the EC2 instance
resource "aws_volume_attachment" "telemetry_subspace_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.telemetry_subspace_node_volume[count.index].id
  instance_id = aws_instance.telemetry_subspace_node[count.index].id
}
