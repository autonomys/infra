provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name    = basename(path.cwd)
  region  = var.region
  region2 = "us-west-1"

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  tags = merge(
    {
      Name = local.name
    },
    var.tags
  )
}

################################################################################
# Auto-Drive VPC
################################################################################

module "vpc" {
  source = "../templates/terraform/aws/vpc"

  name            = "${local.name}-vpc"
  cidr            = var.vpc_cidr
  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Configure NAT gateways and private subnets settings
  enable_nat_gateway = false # Set to true to use NAT gateways and private subnets without public IPs
  single_nat_gateway = false # Set to true to use a single NAT gateway
  tags               = local.tags
}

################################################################################
# Auto-Drive Security Group
################################################################################

resource "aws_security_group" "auto_drive_sg" {
  name        = "auto_drive_sg"
  description = "auto drive security group"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  # Egress Rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "auto-drive-sg"
  }
}

################################################################################
# AMI Data Source
################################################################################

data "aws_ami" "ubuntu_amd64" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"]
}

################################################################################
# Auto-Drive Instances
################################################################################

module "ec2_auto_drive" {
  source = "../templates/terraform/aws/ec2"

  name                        = "${local.name}-backend"
  count                       = var.auto_drive_instance_count
  ami                         = data.aws_ami.ubuntu_amd64.id
  instance_type               = var.auto_drive_instance_type
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [aws_security_group.auto_drive_sg.id]
  associate_public_ip_address = false # Gateway instances use EIPs
  create_eip                  = true
  disable_api_stop            = false

  create_iam_instance_profile = true
  ignore_ami_changes          = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
  root_block_device = [
    {
      device_name = "/dev/sdf"
      encrypted   = true
      volume_type = "gp3"
      throughput  = 250
      volume_size = var.auto_drive_root_volume_size
    }
  ]
  volume_tags = merge(
    { "Name" = "${local.name}-backend-root-volume-${count.index}" },
    var.tags
  )
  tags = merge(local.tags, { Role = "auto-drive" })
}

################################################################################
# Gateway Instances
################################################################################

module "ec2_gateway" {
  source                      = "../templates/terraform/aws/ec2"
  name                        = "${local.name}-gateway"
  count                       = var.gateway_instance_count
  ami                         = data.aws_ami.ubuntu_amd64.id
  instance_type               = var.gateway_instance_type
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [aws_security_group.auto_drive_sg.id]
  associate_public_ip_address = false # Gateway instances use EIPs
  create_eip                  = true
  disable_api_stop            = false

  create_iam_instance_profile = true
  ignore_ami_changes          = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  root_block_device = [
    {
      device_name = "/dev/sdf"
      encrypted   = true
      volume_type = "gp3"
      throughput  = 250
      volume_size = var.gateway_root_volume_size
    }
  ]
  volume_tags = merge(
    { "Name" = "${local.name}-gateway-root-volume-${count.index}" },
    var.tags
  )
  tags = merge(local.tags, { Role = "gateway" })
}
