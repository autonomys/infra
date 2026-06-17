resource "aws_vpc" "telemetry" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "telemetry-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.telemetry.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "telemetry-public-subnet"
  }
}

resource "aws_internet_gateway" "telemetry" {
  vpc_id = aws_vpc.telemetry.id

  tags = {
    Name = "telemetry-igw-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.telemetry.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.telemetry.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.telemetry.id
  }

  tags = {
    Name = "telemetry-public-route-tbl"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "telemetry" {
  name        = "telemetry-subspace-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.telemetry.id

  ingress {
    description = "SSH for VPC"
    from_port   = 22
    to_port     = 22
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
    description = "HTTPS for VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Uptime Kuma"
    from_port   = 3001
    to_port     = 3001
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
}
