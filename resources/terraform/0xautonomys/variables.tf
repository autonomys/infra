variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "vpc_id" {
  description = "VPC ID for the instance and security group"
  type        = string
  default     = "vpc-0d170f772f1c56391"
}

variable "subnet_id" {
  description = "Subnet ID for the instance (leave empty to use first available default subnet)"
  type        = string
  default     = "subnet-0c87d91f0d324335d"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "key_name" {
  description = "Name of the EC2 key pair (must already exist in AWS)"
  type        = string
  default     = "0xautonomys"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access (currently open due to no static IPs)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "launch-wizard-4"
}
