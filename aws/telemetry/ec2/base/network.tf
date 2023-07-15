resource "aws_vpc" "telemetry-vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "telemetry-vpc"
  }
}


resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.telemetry-vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs
  map_public_ip_on_launch = "true"

  tags = {
    Name = "telemetry-public-subnet"
  }
}

resource "aws_security_group" "telemetry-subspace-sg" {
  name        = "telemetry-subspace-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.telemetry-vpc.id

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
    aws_vpc.telemetry-vpc
  ]
}
