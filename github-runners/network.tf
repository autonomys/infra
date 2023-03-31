# data "aws_internet_gateway" "default" {
#   filter {
#     name   = "vpc-*"
#     values = [data.aws_vpc.id]
#   }
# }

resource "aws_internet_gateway" "gw" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "igw"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "public-route-dev" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "gh-runner-route-table"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}


resource "aws_subnet" "dev-subnet" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = var.subnet_prefix[1].cidr_block
  availability_zone = "us-east-1c"

  tags = {
    #Name = "gh-runner-subnet"
    Name = var.subnet_prefix[0].name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table_association" "a-dev-subnet" {
  subnet_id      = aws_subnet.dev-subnet.id
  route_table_id = aws_route_table.public-route-dev.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "TLS for VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    description = "HTTP for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
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
    Name = "allow_web"
  }

  depends_on = [
    data.aws_vpc.default
  ]
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.dev-subnet.id
  private_ips     = local.aws.ipv4_addresses
  security_groups = [aws_security_group.allow_web.id]

  depends_on = [
    aws_security_group.allow_web,
  ]

  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_eip" "web-server-eip" {
  instance                  = aws_instance.web-server.id
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "172.31.2.15"

  depends_on = [
    aws_network_interface.web-server-nic,
    aws_instance.web-server
  ]

  tags = {
    "Name" = "webserver-eip"
  }
  lifecycle {
    prevent_destroy = true
  }
}

