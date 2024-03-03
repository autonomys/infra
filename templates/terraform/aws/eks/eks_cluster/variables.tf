variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "The name of Environment Infrastructure stack, feel free to rename it. Used for cluster and VPC names."
  type        = string
  default     = "subspace-prod"
}

variable "ingress_type" {
  type        = string
  description = "Type of ingress to uses (alb | nginx | ...). this parameter will be sent to arocd via gitops bridge"
  default     = "alb"
}

variable "hosted_zone_name" {
  type        = string
  description = "Route53 domain for the cluster."
  default     = ""
}

variable "eks_admin_role_name" {
  type        = string
  description = "Additional IAM role to be admin in the cluster"
  default     = ""
}

variable "aws_secret_manager_git_private_ssh_key_name" {
  type        = string
  description = "Secret Manager secret name for hosting Github SSH-Key to Access private repository"
  default     = "github-blueprint-ssh-key"
}

variable "argocd_secret_manager_name_suffix" {
  type        = string
  description = "Name of secret manager secret for ArgoCD Admin UI Password"
  default     = "argocd-admin-secret"
}

variable "gitops_addons_org" {
  type        = string
  description = "Git repository org/user contains for addons"
  default     = "git@github.com:subspce"
}
variable "gitops_addons_repo" {
  type        = string
  description = "Git repository contains for addons"
  default     = "infra"
}
variable "gitops_addons_basepath" {
  type        = string
  description = "Git repository base path for addons"
  default     = "argocd/"
}
variable "gitops_addons_path" {
  type        = string
  description = "Git repository path for addons"
  default     = "argocd/bootstrap/control-plane/addons"
}
variable "gitops_addons_revision" {
  type        = string
  description = "Git repository revision/branch/ref for addons"
  default     = "HEAD"
}

variable "gitops_workloads_org" {
  type        = string
  description = "Git repository org/user contains for workloads"
  default     = "git@github.com:subspace"
}

variable "gitops_workloads_repo" {
  type        = string
  description = "Git repository contains for workloads"
  default     = "infra"
}

variable "gitops_workloads_path" {
  type        = string
  description = "Git repo path in workload_repo_url for the ArgoCD workload deployment"
  default     = "envs/argo-cd/"
}

variable "gitops_workloads_revision" {
  type        = string
  description = "Git repo revision in gitops_workloads_url  for the ArgoCD workload deployment"
  default     = "main"
}

variable "service_name" {
  description = "The name of the Suffix for the stack name"
  type        = string
  default     = "blue"
}

variable "cluster_version" {
  description = "The Version of Kubernetes to deploy"
  type        = string
  default     = "1.28"
}

variable "argocd_route53_weight" {
  description = "The Route53 weighted records weight for argocd application"
  type        = string
  default     = "100"
}

variable "ecsfrontend_route53_weight" {
  description = "The Route53 weighted records weight for ecsdeo-frontend application"
  type        = string
  default     = "100"
}

variable "route53_weight" {
  description = "The Route53 weighted records weight for others application"
  type        = string
  default     = "100"
}

variable "app_name" {
  description = "team app name"
  type        = string
  default     = "subspace-team-ops"

}

variable "project_name" {
  description = "team project name"
  type        = string
  default     = "subspace-infra"
}

variable "team_labels" {
  description = "Map of team-specific labels"
  type = map(object({
    labels = map(string)
  }))
  default = {
    devops = {
      labels = {
        "elbv2.k8s.aws/pod-readiness-gate-inject" = "enabled",
        "appName"                                 = "subspace-ops",
        "projectName"                             = "Subspace-infra",
      }
    }
    devs = {
      labels = {
        "elbv2.k8s.aws/pod-readiness-gate-inject" = "enabled",
        "appName"                                 = "subspace-explorers",
        "projectName"                             = "explorers",
        "pod-security.kubernetes.io/enforce"      = "restricted",
      }
    }
  }
}

variable "resource_quota" {
  description = "Resource quota settings for the Kubernetes namespace"
  type = object({
    hard = map(string)
  })
  default = {
    hard = {
      "requests.cpu"    = "100",
      "requests.memory" = "20Gi",
      "limits.cpu"      = "400",
      "limits.memory"   = "32Gi",
      "pods"            = "100",
      "secrets"         = "10",
      "services"        = "20"
    }
  }
}

variable "limit_range" {
  description = "Limit range settings for Kubernetes"
  type = object({
    limit = list(object({
      type    = string
      max     = optional(map(string))
      min     = optional(map(string))
      default = optional(map(string))
    }))
  })
  default = {
    limit = [
      {
        type = "Pod"
        max = {
          cpu    = "2"
          memory = "1Gi"
        }
        min = {
          cpu    = "10m"
          memory = "4Mi"
        }
      },
      {
        type = "PersistentVolumeClaim"
        min = {
          storage = "20G"
        }
      },
      {
        type = "Container"
        default = {
          cpu    = "50m"
          memory = "24Mi"
        }
      }
    ]
  }
}
