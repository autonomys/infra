# Variables for rancher common module
variable "node_public_ip" {
  type        = string
  description = "Public IP of compute node for Rancher cluster"
}

variable "node_internal_ip" {
  type        = string
  description = "Internal IP of compute node for Rancher cluster"
  default     = ""
}
variable "node_username" {
  type        = string
  description = "Username used for SSH access to the Rancher server cluster node"
}
variable "ssh_private_key_pem" {
  type        = string
  description = "Private key used for SSH access to the Rancher server cluster node"
}

variable "rancher_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server cluster"
  default     = "v1.29.0+k3s1"
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for managed workload cluster"
  default     = "v1.28.4+rke2r1"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher"
  default     = "1.12.7"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version"
  default     = "2.8.0"
}
variable "rancher_server_dns" {
  type        = string
  description = "DNS host name of the Rancher server"
}
variable "admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap, min. 12 characters"
}
variable "workload_cluster_name" {
  type        = string
  description = "Name for created custom workload cluster"
}

variable "rancher_helm_repository" {
  type        = string
  description = "The helm repository, where the Rancher helm chart is installed from"
  default     = "https://releases.rancher.com/server-charts/latest"
}
