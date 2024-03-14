module "telemetry_vpc" {
  source = "../../terraform/aws/vpc"

  cidr_block           = var.public_subnet_cidrs
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "telemetry-vpc"
  }
}


resource "aws_subnet" "public_subnets" {
  vpc_id                  = module.telemetry-vpc.id
  cidr_block              = var.public_subnet_cidrs
  availability_zone       = var.azs
  map_public_ip_on_launch = "true"

  tags = {
    Name = "telemetry-public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = module.telemetry-vpc.id

  tags = {
    Name = "telemetry-igw-public-subnet"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = module.telemetry-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "telemetry-public-route-tbl"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_route_table_association" "public_route_table_subnets_association" {
  subnet_id      = aws_subnet.public_subnets.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_security_group" "telemetry-subspace-sg" {
  name        = "telemetry-subspace-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = module.telemetry-vpc.id

  ingress {
    description = "HTTPS for VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH for VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "egress for VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "telemetry-subspace-sg"
  }

  depends_on = [
    module.telemetry_vpc
  ]
}
