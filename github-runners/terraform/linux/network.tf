# data "aws_internet_gateway" "gh-runners" {
#   filter {
#     name   = "vpc-*"
#     values = [aws_vpc.id]
#   }
# }

resource "aws_vpc" "gh-runners" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name = "gh-runners"
  }
}

resource "aws_internet_gateway" "gw" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.gh-runners.id

  tags = {
    Name = "igw"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.gh-runners.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.gh-runners.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }

  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_route_table" "public-route" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.gh-runners.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[count.index].id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw[count.index].id
  }

  tags = {
    Name = "gh-runner-route-table"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_route_table_association" "a-public_subnets" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public-route[count.index].id
}

resource "aws_security_group" "allow_runner" {
  name        = "allow_runner"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.gh-runners.id

  ingress {
    description = "TLS for VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.gh-runners.cidr_block]
  }

  ingress {
    description = "HTTP for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.gh-runners.cidr_block]
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
    Name = "allow_runner"
  }

  depends_on = [
    aws_vpc.gh-runners
  ]
}

resource "aws_network_interface" "runner-server-nic" {
  count           = length(var.public_subnet_cidrs)
  subnet_id       = aws_subnet.public_subnets[count.index].id
#  private_ips     = ["172.31.1.17"]
  security_groups = [aws_security_group.allow_runner.id]

  depends_on = [
    aws_security_group.allow_runner,
  ]

  lifecycle {
    prevent_destroy = false
  }
}


resource "aws_eip" "runner-server-eip" {
  count                     = length(var.public_subnet_cidrs)
  instance                  = aws_instance.linux-runner[count.index].id
  vpc                       = true
  network_interface         = aws_network_interface.runner-server-nic[count.index].id
  associate_with_private_ip = aws_instance.linux-runner[count.index].private_ip

  depends_on = [
    aws_network_interface.runner-server-nic,
    aws_instance.linux-runner
  ]

  tags = {
    "Name" = "runner-server-eip"
  }
  lifecycle {
    prevent_destroy = false
  }
}

