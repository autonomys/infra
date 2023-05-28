resource "aws_vpc" "gemini-explorer-vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "gemini-explorer-vpc"
  }
}


resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.gemini-explorer-vpc
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}


resource "aws_internet_gateway" "gw" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.gemini-explorer-vpc

  tags = {
    Name = "igw-public-subnet-${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}


resource "aws_route_table" "public_route_table" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.gemini-explorer-vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[count.index].id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw[count.index].id
  }

  tags = {
    Name = "public-route-tbl-${count.index}"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}


resource "aws_route_table_association" "private_route_table_subnets_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}


resource "aws_security_group" "gemini-explorer-sg" {
  name        = "gemini-explorer-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.gemini-explorer-vpc

  ingress {
    description = "HTTPS for VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.gemini-explorer-vpc.cidr_block]
  }

  ingress {
    description = "HTTP for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.gemini-explorer-vpc.cidr_block]
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
    Name = "gemini-explorer-sg"
  }

  depends_on = [
    aws_vpc.gemini-explorer-vpc
  ]
}

## Allocate EIP to NAT Gateway

resource "aws_eip" "public_subnet_eip" {
  count = length(var.public_subnet_cidrs)
  vpc   = true

  depends_on = [
    aws_internet_gateway.gw,
  ]
}

# NAT Gateway for public subnet
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = element(aws_eip.public_subnet_eip.*.allocation_id, count.index)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)

  tags = {
    Name = "public-subnet-nat-GTW-${count.index}"
  }
}
