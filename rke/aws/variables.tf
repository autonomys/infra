# Variables for AWS infrastructure module
variable "aws_access_key" {
  type        = string
  description = "AWS access key used to create infrastructure"
}
variable "aws_secret_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
}

variable "aws_session_token" {
  type        = string
  description = "AWS session token used to create AWS infrastructure"
  default     = ""
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-2"
}

variable "aws_zone" {
  type        = string
  description = "AWS zone used for all resources"
  default     = "us-east-2a"
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "subspace"
}

variable "instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "m6i.xlarge"
}

variable "rancher_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server cluster"
  default     = "v1.26.4+k3s1"
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for managed workload cluster"
  default     = "v1.27.1+rke2r1"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher"
  default     = "1.11.0"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version"
  default     = "2.7.3"
}

variable "rancher_helm_repository" {
  type        = string
  description = "The helm repository, where the Rancher helm chart is installed from"
  default     = "https://releases.rancher.com/server-charts/latest"
}
variable "rancher_server_admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap, min. 12 characters"
}

# Local variables used to reduce repetition
locals {
  node_username = "ubuntu"
}
