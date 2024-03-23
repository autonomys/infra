provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host = aws_eks_cluster.vault.endpoint

  cluster_ca_certificate = base64decode(
    aws_eks_cluster.vault.certificate_authority[0].data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host = aws_eks_cluster.vault.endpoint
    cluster_ca_certificate = base64decode(
      aws_eks_cluster.vault.certificate_authority[0].data
    )
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      command     = "aws"
    }
  }
}
