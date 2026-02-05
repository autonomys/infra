resource "aws_vpc" "network_vpc" {
  cidr_block                       = var.aws.vpc_cidr_block
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    name = var.aws.vpc_id
  }
}

resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.network_vpc.id
  cidr_block              = var.aws.public_subnet_cidrs
  ipv6_cidr_block         = cidrsubnet(aws_vpc.network_vpc.ipv6_cidr_block, 8, 0)
  availability_zone       = var.aws.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.instance.network_name}-public-subnet-chain-indexer"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.network_vpc.id

  tags = {
    Name = "${var.instance.network_name}-igw-public-subnet-chain-indexer"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.network_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.instance.network_name}-public-route-tbl-chain-indexer"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_route_table_association" "public_route_table_subnets_association" {
  subnet_id      = aws_subnet.public_subnets.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "network_sg" {
  name        = "${var.instance.network_name}-network-chain-indexer-sg"
  description = "Allow SSH and outbound traffic"
  vpc_id      = aws_vpc.network_vpc.id

  ingress {
    description      = "SSH for VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS for VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP for VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "egress for VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.instance.network_name}-chain-indexer-sg"
  }

  depends_on = [
    aws_vpc.network_vpc
  ]
}
