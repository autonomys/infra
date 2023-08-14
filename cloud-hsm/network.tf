resource "aws_vpc" "cloudhsm_vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "${var.vpc_id}"
  }
}

resource "aws_subnet" "cloudhsm_public_subnet" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.cloudhsm_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.vpc_id}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "cloudhsm_private_subnet" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.cloudhsm_vpc.id
  cidr_block              = element(var.private_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = "false"

  tags = {
    Name = "${var.vpc_id}-private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "cloudhsm_gw" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.cloudhsm_vpc.id

  tags = {
    Name = "${var.vpc_id}-igw-public-subnet-${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table" "cloudhsm_public_route_table" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.cloudhsm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudhsm_gw[count.index].id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.cloudhsm_gw[count.index].id
  }

  tags = {
    Name = "${var.vpc_id}-public-route-tbl-${count.index}"
  }

  depends_on = [
    aws_internet_gateway.cloudhsm_gw
  ]
}

resource "aws_route_table_association" "cloudhsm_public_route_table_subnets_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.cloudhsm_public_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.cloudhsm_public_route_table.*.id, count.index)
}


resource "aws_route_table" "cloudhsm_private_route_table" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.cloudhsm_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cloudhsm_nat_gateway[count.index].id
  }

  tags = {
    Name = "${var.vpc_id}-private-route-tbl-${count.index}"
  }
}

resource "aws_route_table_association" "cloudhsm_private_route_table_subnets_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.cloudhsm_private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.cloudhsm_private_route_table.*.id, count.index)
}


resource "aws_security_group" "cloudhsm_sg" {
  name        = "cloudhsm_sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.cloudhsm_vpc.id

  ingress {
    description = "SSH for VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP for VPC"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Cloud HSM client Daemon"
    from_port   = 2223
    to_port     = 2225
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
    Name = "${var.vpc_id}-sg"
  }

  depends_on = [
    aws_vpc.cloudhsm_vpc
  ]
}

## Allocate EIP to NAT Gateway

resource "aws_eip" "cloudhsm_public_subnet_eip" {
  count = length(var.public_subnet_cidrs)
  vpc   = true

  depends_on = [
    aws_internet_gateway.cloudhsm_gw,
  ]
}

# NAT Gateway for public subnet
resource "aws_nat_gateway" "cloudhsm_nat_gateway" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = element(aws_eip.cloudhsm_public_subnet_eip.*.allocation_id, count.index)
  subnet_id     = element(aws_subnet.cloudhsm_public_subnet.*.id, count.index)

  tags = {
    Name = "${var.vpc_id}-public-subnet-nat-GTW-${count.index}"
  }
}
