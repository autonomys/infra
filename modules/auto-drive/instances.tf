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
# Auto-Drive Backend Instances
################################################################################

module "ec2_backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  count                       = var.instances.backend_count
  name                        = try(var.instances.backend_names[count.index], "${local.name}-backend-${count.index}")
  ami                         = data.aws_ami.ubuntu_amd64.id
  instance_type               = var.instances.backend_instance_type
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [aws_security_group.auto_drive_sg.id]
  associate_public_ip_address = true
  create_eip                  = true
  disable_api_stop            = false

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-backend"
  create_security_group       = false
  ignore_ami_changes          = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  # TODO: Plan IMDSv2 migration (change to "required") after verifying app compatibility
  metadata_options = {
    http_tokens = "optional"
  }

  enable_volume_tags = false
  root_block_device = {
    encrypted  = true
    type       = "gp3"
    throughput = 250
    size       = var.instances.backend_volume_size
    tags = merge(
      { "Name" = "${local.name}-backend-root-volume-${count.index}" },
      var.tags
    )
  }
  tags = merge(local.tags, { Role = "auto-drive" })
}

################################################################################
# Gateway Instances
################################################################################

module "ec2_gateway" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  count                       = var.instances.gateway_count
  name                        = try(var.instances.gateway_names[count.index], "${local.name}-gateway-${count.index}")
  ami                         = data.aws_ami.ubuntu_amd64.id
  instance_type               = var.instances.gateway_instance_type
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [aws_security_group.auto_drive_sg.id]
  associate_public_ip_address = true
  create_eip                  = true
  disable_api_stop            = false

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-gateway"
  create_security_group       = false
  ignore_ami_changes          = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  metadata_options = {
    http_tokens = "optional"
  }

  enable_volume_tags = false
  root_block_device = {
    encrypted  = true
    type       = "gp3"
    throughput = 250
    size       = var.instances.gateway_volume_size
    tags = merge(
      { "Name" = "${local.name}-gateway-root-volume-${count.index}" },
      var.tags
    )
  }
  tags = merge(local.tags, { Role = "gateway" })
}

