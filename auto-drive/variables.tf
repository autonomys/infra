# AWS Region
variable "region" {
  description = "AWS region where the resources will be created."
  type        = string
  default     = "us-west-2"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# Availability Zones
variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 3
}

# Tags
variable "tags" {
  description = "Tags to assign to all resources."
  type        = map(string)
  default = {
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  }
}

# Auto-Drive Instance Configuration
variable "auto_drive_instance_type" {
  description = "Instance type for auto-drive instances."
  type        = string
  default     = "m7a.2xlarge"
}

variable "auto_drive_root_volume_size" {
  description = "Size of the root volume (in GB) for auto-drive instances."
  type        = number
  default     = 500
}

# Gateway Instance Configuration
variable "gateway_instance_type" {
  description = "Instance type for gateway instances."
  type        = string
  default     = "m7a.2xlarge"
}

variable "gateway_root_volume_size" {
  description = "Size of the root volume (in GB) for gateway instances."
  type        = number
  default     = 100
}

variable "iam_role_policy_arn" {
  description = "IAM policy ARN to attach to instance role."
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "kms_key_id" {
  description = "KMS key ARN for EBS volume encryption."
  type        = string
  default     = "" # Replace with your desired KMS Key ARN or leave empty
}

# Optional: Number of Instances for Each Module
variable "auto_drive_instance_count" {
  description = "Number of auto-drive instances to create."
  type        = number
  default     = 1
}

variable "gateway_instance_count" {
  description = "Number of gateway instances to create."
  type        = number
  default     = 1
}

variable "ingress_cidr_blocks" {
  description = "List of CIDR blocks for ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Open to all; adjust as needed
}

variable "ingress_rules" {
  description = "List of ingress rules to apply"
  type        = list(string)
  default     = ["ssh", "http", "https"]
}

variable "rules" {
  description = "Map of predefined rules"
  type        = map(list(string))
  default = {
    ssh   = [22, 22, "tcp", "SSH access"]
    http  = [80, 80, "tcp", "HTTP access"]
    https = [443, 443, "tcp", "HTTPS access"]
  }
}

variable "rabbitmq_username" {
  description = "RabbitMQ username"
  type        = string
  default     = "guru"
  sensitive   = true
}

variable "rabbitmq_replication_username" {
  description = "RabbitMQ replication username"
  type        = string
  default     = "guru2"
  sensitive   = true
}

variable "rabbitmq_instance_type" {
  description = "Instance type for RabbitMQ broker instances."
  type        = string
  default     = "mq.t3.micro"
}

variable "rabbitmq_version" {
  description = "RabbitMQ version."
  type        = string
  default     = "3.13"
}

variable "rabbitmq_deployment_mode_staging" {
  description = "RabbitMQ deployment mode."
  type        = string
  default     = "SINGLE_INSTANCE"
}


variable "rabbitmq_deployment_mode_production" {
  description = "RabbitMQ deployment mode."
  type        = string
  default     = "CLUSTER_MULTI_AZ"
}
