# Create EBS volumes
resource "aws_ebs_volume" "squid_blue_node_volume" {
  count             = length(var.aws_region) * var.blue-squid-node-config.instance-count-blue
  availability_zone = element(var.azs, 0)

  size = 800   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "squid_blue_node_volume_${count.index}"
  }
}

# Attach the EBS volumes to the EC2 instance
resource "aws_volume_attachment" "squid_blue_node_volume_attachment" {
  count       = length(var.aws_region) * var.blue-squid-node-config.instance-count-blue
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.squid_blue_node_volume[count.index].id
  instance_id = aws_instance.squid_blue_node[count.index].id
}

# Create EBS volumes
resource "aws_ebs_volume" "squid_green_node_volume" {
  count             = length(var.aws_region) * var.green-squid-node-config.instance-count-green
  availability_zone = element(var.azs, 0)

  size = 800   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "squid_green_node_volume_${count.index}"
  }
}

# Attach the EBS volumes to the EC2 instance
resource "aws_volume_attachment" "squid_green_node_volume_attachment" {
  count       = length(var.aws_region) * var.green-squid-node-config.instance-count-green
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.squid_green_node_volume[count.index].id
  instance_id = aws_instance.squid_green_node[count.index].id
}
