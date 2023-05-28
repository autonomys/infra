resource "aws_iam_role" "self_managed_ng" {
  count = local.self_managed_node_group["create_iam_role"] ? 1 : 0

  name                  = "${var.context.eks_cluster_id}-${local.self_managed_node_group["node_group_name"]}"
  description           = "EKS Self Managed Node group IAM Role"
  assume_role_policy    = data.aws_iam_policy_document.self_managed_ng_assume_role_policy.json
  path                  = var.context.iam_role_path
  permissions_boundary  = var.context.iam_role_permissions_boundary
  force_detach_policies = true
  tags                  = var.context.tags
}

resource "aws_iam_instance_profile" "self_managed_ng" {
  count = local.self_managed_node_group["create_iam_role"] ? 1 : 0

  name = "${var.context.eks_cluster_id}-${local.self_managed_node_group["node_group_name"]}"
  role = aws_iam_role.self_managed_ng[0].name

  path = var.context.iam_role_path
  tags = var.context.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "self_managed_ng" {
  for_each   = local.eks_worker_policies
  policy_arn = each.key
  role       = aws_iam_role.self_managed_ng[0].name
}
