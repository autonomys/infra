resource "aws_vpc" "network_vpc" {
  cidr_block                       = var.vpc_cidr_block
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    name = "${var.network_name}-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.network_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  ipv6_cidr_block         = cidrsubnet(aws_vpc.network_vpc.ipv6_cidr_block, 8, count.index)
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.network_name}-public-subnet-${count.index}"
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
  subnet_id      = aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_route_table.*.id[count.index]
}

resource "aws_security_group" "network_sg" {
  name        = "${var.network_name}-network-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.network_vpc.id

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

  ingress {
    description      = "SSH for VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Node Port 30333 for VPC"
    from_port        = 30333
    to_port          = 30333
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Node Port 30433 for VPC"
    from_port        = 30433
    to_port          = 30433
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Node Port 30334 Domain port for VPC"
    from_port        = 30334
    to_port          = 30334
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Farmer Port 30533 for VPC"
    from_port        = 30533
    to_port          = 30533
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # UDP ports

  ingress {
    description      = "Node UDP Port 30333 for VPC"
    from_port        = 30333
    to_port          = 30333
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Node UDP Port 30433 for VPC"
    from_port        = 30433
    to_port          = 30433
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Node UDP Port 30334 Domain port for VPC"
    from_port        = 30334
    to_port          = 30334
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  ingress {
    description      = "Farmer UDP Port 30533 for VPC"
    from_port        = 30533
    to_port          = 30533
    protocol         = "udp"
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
    Name = "${var.network_name}_sg"
  }

  depends_on = [
    aws_vpc.network_vpc
  ]
}
