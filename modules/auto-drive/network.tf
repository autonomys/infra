data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "auto-drive"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.vpc.az_count)

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
    },
    var.tags
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name            = "${local.name}-vpc"
  cidr            = var.vpc.cidr
  azs             = local.azs
  private_subnets = var.vpc.private_subnets
  public_subnets  = var.vpc.public_subnets

  enable_nat_gateway = false
  single_nat_gateway = false
  tags               = local.tags
}
