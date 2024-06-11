resource "aws_lb" "nlb" {
  name               = "${var.environment_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.eks_cluster.vpc_public_subnets

  tags = {
    Name = "${var.environment_name}-nlb"
  }
}

# Define target groups and listeners for TCP ports
locals {
  tcp_ports = [30333, 30433, 30334, 40333, 30533]
}

resource "aws_lb_target_group" "tg_tcp" {
  count = length(local.tcp_ports)

  name     = "${var.environment_name}-tg-tcp-${local.tcp_ports[count.index]}"
  port     = local.tcp_ports[count.index]
  protocol = "TCP"
  vpc_id   = module.eks_cluster.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    port                = local.tcp_ports[count.index] # Use the same port for health checks
    protocol            = "TCP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.environment_name}-tg-tcp-${local.tcp_ports[count.index]}"
  }
}

resource "aws_lb_listener" "nlb_listener_tcp" {
  count = length(local.tcp_ports)

  load_balancer_arn = aws_lb.nlb.arn
  port              = local.tcp_ports[count.index]
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_tcp[count.index].arn
  }
}

# Define target groups and listeners for UDP ports
locals {
  udp_ports = [30333, 30433, 30334, 30533]
}

resource "aws_lb_target_group" "tg_udp" {
  count = length(local.udp_ports)

  name     = "${var.environment_name}-tg-udp-${local.udp_ports[count.index]}"
  port     = local.udp_ports[count.index]
  protocol = "UDP"
  vpc_id   = module.eks_cluster.vpc_id

  health_check {
    enabled = false # UDP health checks are not supported
  }

  tags = {
    Name = "${var.environment_name}-tg-udp-${local.udp_ports[count.index]}"
  }
}

resource "aws_lb_listener" "nlb_listener_udp" {
  count = length(local.udp_ports)

  load_balancer_arn = aws_lb.nlb.arn
  port              = local.udp_ports[count.index]
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_udp[count.index].arn
  }
}

# Define security group rules for EKS cluster
resource "aws_security_group" "eks_security_group_network" {
  name        = "${var.environment_name}-eks-sg-network"
  description = "Security group for EKS cluster"
  vpc_id      = module.eks_cluster.vpc_id

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
    description      = "Domain Operator Node Port 40333 for VPC"
    from_port        = 40333
    to_port          = 40333
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
}
