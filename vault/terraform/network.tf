# Create a VPC
resource "aws_vpc" "vault_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "vault_subnet" {
  vpc_id            = aws_vpc.vault_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

# Create a security group
resource "aws_security_group" "vault_sg" {
  vpc_id = aws_vpc.vault_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
