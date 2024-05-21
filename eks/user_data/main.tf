locals {
  name = "ex-${replace(basename(path.cwd), "_", "-")}"

  cluster_endpoint          = "https://012345678903AB2BAE5D1E0BFE0E2B50.gr7.us-east-2.eks.amazonaws.com"
  cluster_auth_base64       = var.cluster_auth_base64
  cluster_service_ipv4_cidr = "172.16.0.0/16"
}

#############################
# User Data Module
#############################

# EKS managed node group - bottlerocket
module "eks_mng_bottlerocket_no_op" {
  source = "../../templates/terraform/aws/eks/_user_data"

  platform = "bottlerocket"
}

module "eks_mng_bottlerocket_additional" {
  source = "../../templates/terraform/aws/eks/_user_data"

  platform = "bottlerocket"

  bootstrap_extra_args = var.bootstrap_extra_args
}

module "eks_mng_bottlerocket_custom_ami" {
  source = "../../templates/terraform/aws/eks/_user_data"

  platform = "bottlerocket"

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  enable_bootstrap_user_data = true

  bootstrap_extra_args = var.bootstrap_extra_args
}

module "eks_mng_bottlerocket_custom_template" {
  source = "../../templates/terraform/aws/eks/_user_data"

  platform = "bottlerocket"

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  user_data_template_path = "${path.module}/templates/bottlerocket_custom.tpl"

  bootstrap_extra_args = var.bootstrap_extra_args
}
