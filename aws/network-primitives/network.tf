resource "aws_vpc" "network_vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "${var.network_name}-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.network_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.network_name}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.network_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.network_name}-private-subnet-${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }

}


resource "aws_internet_gateway" "gw" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.network_vpc.id

  tags = {
    Name = "${var.network_name}-igw-public-subnet-${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table" "public_route_table" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.network_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[count.index].id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw[count.index].id
  }

  tags = {
    Name = "${var.network_name}-public-route-tbl-${count.index}"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_route_table_association" "public_route_table_subnets_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
}


resource "aws_route_table" "private_route_table" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.network_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "${var.network_name}-private-route-tbl-${count.index}"
  }
}

resource "aws_route_table_association" "private_route_table_subnets_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}

resource "aws_security_group" "network_sg" {
  name        = "network_sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.network_vpc.id

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

  ingress {
    description = "Node Port 30333 for VPC"
    from_port   = 30333
    to_port     = 30333
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node Port 30433 for VPC"
    from_port   = 30433
    to_port     = 30433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Farmer Port 30533 for VPC"
    from_port   = 30533
    to_port     = 30533
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "DSN Port 50000 for VPC"
    from_port   = 50000
    to_port     = 50000
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
    Name = "${var.network_name}_sg"
  }

  depends_on = [
    aws_vpc.network_vpc
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
    Name = "${var.network_name}-public-subnet-nat-GTW-${count.index}"
  }
}
