module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.16.0"

  name = "${var.prefix}-vpc"
  cidr = "172.31.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["172.31.1.0/24", "172.31.2.0/24"]
  #public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_hostnames    = true
  enable_nat_gateway      = true
  map_public_ip_on_launch = false
  single_nat_gateway      = true
  enable_vpn_gateway = false
}
