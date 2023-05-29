# Create EBS volumes
resource "aws_ebs_volume" "bootstrap_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 100   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "bootstrap_node_volume_${count.index}"
  }
}

# Attach the EBS volumes to the EC2 instance
resource "aws_volume_attachment" "boostrap_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.bootstrap_node_volume[count.index].id
  instance_id = aws_instance.bootstrap_node[count.index].id
}

resource "aws_ebs_volume" "full_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 100   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "full_node_volume_${count.index}"
  }
}

resource "aws_volume_attachment" "full_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.full_node_volume[count.index].id
  instance_id = aws_instance.full_node[count.index].id
}

resource "aws_ebs_volume" "rpc_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 100   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "rpc_node_volume_${count.index}"
  }
}

resource "aws_volume_attachment" "rpc_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.rpc_node_volume[count.index].id
  instance_id = aws_instance.rpc_node[count.index].id
}

resource "aws_ebs_volume" "domain_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 100   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "domain_node_volume_${count.index}"
  }
}


resource "aws_volume_attachment" "domain_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.domain_node_volume[count.index].id
  instance_id = aws_instance.domain_node[count.index].id
}

resource "aws_ebs_volume" "farmer_node_volume" {
  count             = length(var.aws_region) * var.instance_count
  availability_zone = "us-east-1a"

  size = 100   # volume size (in GB)
  type = "gp3" # volume type

  tags = {
    Name = "farmer_node_volume-${count.index}"
  }
}

resource "aws_volume_attachment" "farmer_node_attachment" {
  count       = length(var.aws_region) * var.instance_count
  device_name = "/dev/sdf" # device name
  volume_id   = aws_ebs_volume.farmer_node_volume[count.index].id
  instance_id = aws_instance.farmer_node[count.index].id
}
