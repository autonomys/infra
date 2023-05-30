# Create EBS volumes
resource "aws_ebs_volume" "squid_blue_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 100   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "squid_blue_node_volume_${count.index}"
  }
}

# Attach the EBS volumes to the EC2 instance
resource "aws_volume_attachment" "squid_blue_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.squid_blue_node_volume[count.index].id
  instance_id = aws_instance.squid_blue_node[count.index].id
}

# Create EBS volumes
resource "aws_ebs_volume" "squid_green_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 100   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "squid_green_node_volume_${count.index}"
  }
}

# Attach the EBS volumes to the EC2 instance
resource "aws_volume_attachment" "squid_green_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.squid_green_node_volume[count.index].id
  instance_id = aws_instance.squid_green_node[count.index].id
}

resource "aws_ebs_volume" "archive_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 600   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "archive_node_volume_${count.index}"
  }
}

resource "aws_volume_attachment" "archive_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.archive_node_volume[count.index].id
  instance_id = aws_instance.archive_node[count.index].id
}
