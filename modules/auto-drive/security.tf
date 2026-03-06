resource "aws_security_group" "auto_drive_sg" {
  name        = "auto_drive_sg"
  description = "auto drive security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  egress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = var.vpc.private_subnets
  }

  egress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = var.vpc.private_subnets
  }

  tags = {
    Name = "auto-drive-sg"
  }
}
