resource "aws_vpc" "gemini-squid-vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.network_name}-squid-vpc"
    name = "${var.network_name}-squid-vpc"
  }
}


resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.gemini-squid-vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.network_name}-squid-public-subnet-${count.index}"
  }
}


resource "aws_internet_gateway" "squid-gw" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.gemini-squid-vpc.id

  tags = {
    Name = "${var.network_name}-squid-gw-public-subnet-${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}


resource "aws_route_table" "public_route_table" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.gemini-squid-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.squid-gw[count.index].id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.squid-gw[count.index].id
  }

  tags = {
    Name = "${var.network_name}-squid-public-route-tbl-${count.index}"
  }

  depends_on = [
    aws_internet_gateway.squid-gw
  ]
}

resource "aws_route_table_association" "public_route_table_subnets_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
}

resource "aws_security_group" "gemini-squid-sg" {
  name        = "${var.network_name}-squid-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.gemini-squid-vpc.id

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
    Name = "${var.network_name}-squid-sg"
  }

  depends_on = [
    aws_vpc.gemini-squid-vpc
  ]
}
