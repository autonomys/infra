# You should update the below variables
aws_region          = "us-east-2"
environment_name    = "cluster"
hosted_zone_name    = "eks.subspace.network" # Existing Hosted Zone (create one to be managed by route53 since subspace.network is managed with Cloudflare)
eks_admin_role_name = ""                     # Additional role admin in the cluster (usually the role I use in the AWS console)

gitops_addons_org      = "git@github.com:subspace"
gitops_addons_repo     = "infra"
gitops_addons_path     = "argocd/bootstrap/control-plane/addons"
gitops_addons_basepath = "argocd/"

# EKS Blueprint Workloads ArgoCD App of App repository
gitops_workloads_org      = "git@github.com:subspace"
gitops_workloads_repo     = "infra"
gitops_workloads_revision = "main"
gitops_workloads_path     = "envs/argocd/green"


#Secret manager secret for github ssk key
aws_secret_manager_git_private_ssh_key_name = "github-eks-subspace-ssh-key"
