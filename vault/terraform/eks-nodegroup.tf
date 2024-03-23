resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.vault.name
  node_group_name = "private-node-group-vault"
  node_role_arn   = aws_iam_role.node-group.arn
  subnet_ids      = [for s in aws_subnet.private : s.id]

  labels = {
    "type" = "private"
    "tool" = "vault"
  }

  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 3
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node-group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-group-AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Environment = "production"
  }
}

resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.vault.name
  node_group_name = "public-node-group-vault"
  node_role_arn   = aws_iam_role.node-group.arn
  subnet_ids      = [for s in aws_subnet.public : s.id]

  labels = {
    "type" = "public"
  }

  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-group-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Environment = "production"
  }
}

resource "aws_iam_role" "node-group" {
  name = "eks-node-group-role-vault"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-group.name
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-group.name
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-group.name
}

resource "aws_iam_role_policy" "node-group-ClusterAutoscalerPolicy" {
  name = "eks-cluster-auto-scaler"
  role = aws_iam_role.node-group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.eks_cluster_name}/ClusterSharedNodeSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.vault.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.vault.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.eks_cluster_name}/ClusterSharedNodeSecurityGroup"
    Environment = "production"
  }
}
