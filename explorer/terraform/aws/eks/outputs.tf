#-------------------------------
# EKS Cluster Module Outputs
#-------------------------------
output "eks_cluster_arn" {
  description = "Amazon EKS Cluster Name"
  value       = module.aws_eks.cluster_arn
}

output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.aws_eks.cluster_id
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.aws_eks.cluster_certificate_authority_data
}

output "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.aws_eks.cluster_endpoint
}


output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.context.aws_region_name} update-kubeconfig --name ${module.aws_eks.cluster_id}"
}

output "eks_cluster_status" {
  description = "Amazon EKS Cluster Status"
  value       = module.aws_eks.cluster_status
}

output "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.aws_eks.cluster_version
}

#-------------------------------
# Cluster Security Group
#-------------------------------
output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = module.aws_eks.cluster_primary_security_group_id
}

output "cluster_security_group_id" {
  description = "EKS Control Plane Security Group ID"
  value       = module.aws_eks.cluster_security_group_id
}

output "cluster_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = module.aws_eks.cluster_security_group_arn
}

#-------------------------------
# EKS Worker Security Group
#-------------------------------
output "worker_node_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the worker node shared security group"
  value       = try(module.aws_eks.node_security_group_arn, "EKS Node groups not enabled")
}

output "worker_node_security_group_id" {
  description = "ID of the worker node shared security group"
  value       = try(module.aws_eks.node_security_group_id, "EKS Node groups not enabled")
}

#---------------------------------
# Self-managed Node Groups Outputs
#---------------------------------
output "self_managed_node_groups" {
  description = "Outputs from EKS Self-managed node groups "
  value       = var.create_eks && length(var.self_managed_node_groups) > 0 ? module.aws_eks_self_managed_node_groups[*] : []
}

output "self_managed_node_group_iam_role_arns" {
  description = "IAM role arn's of self managed node groups"
  value       = var.create_eks && length(var.self_managed_node_groups) > 0 ? values({ for nodes in sort(keys(var.self_managed_node_groups)) : nodes => join(",", module.aws_eks_self_managed_node_groups[nodes].self_managed_nodegroup_iam_role_arns) }) : []
}

output "self_managed_node_group_autoscaling_groups" {
  description = "Autoscaling group names of self managed node groups"
  value       = var.create_eks && length(var.self_managed_node_groups) > 0 ? values({ for nodes in sort(keys(var.self_managed_node_groups)) : nodes => join(",", module.aws_eks_self_managed_node_groups[nodes].self_managed_asg_names) }) : []
}

output "self_managed_node_group_iam_instance_profile_id" {
  description = "IAM instance profile id of managed node groups"
  value       = var.create_eks && length(var.self_managed_node_groups) > 0 ? values({ for nodes in sort(keys(var.self_managed_node_groups)) : nodes => join(",", module.aws_eks_self_managed_node_groups[nodes].self_managed_nodegroup_iam_instance_profile_id) }) : []
}

output "self_managed_node_group_aws_auth_config_map" {
  description = "Self managed node groups AWS auth map"
  value       = local.self_managed_node_group_aws_auth_config_map[*]
}


#-------------------------------
# Teams(Soft Multi-tenancy) Outputs
#-------------------------------
output "teams" {
  description = "Output of the teams module. This contains the IAM roles arn of platform and application teams"
  value       = var.create_eks && (length(var.platform_teams) > 0 || length(var.application_teams) > 0) ? module.aws_eks_teams[*] : []
}
