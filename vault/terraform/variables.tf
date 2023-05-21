# Variables
variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The region to run the AWS resources"
  type        = string
  default     = "us-east-2"
}

variable "aws_az" {
  description = "The availability to run the AWS resources"
  type        = string
  default     = "us-east-2a"
}

variable vault_version {
  type = string
  default = "1.13.2"
}
variable "vault_admin_token" {
  description = "The region to run the AWS resources"
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  type        = string
  default     = "deployer"
}

variable "private_key_path" {
  type    = string
  default = ""
}

variable "vault_instance_type" {
  description = "The type of EC2 Instance to run in the Vault ASG"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = null
}

variable "s3_bucket_name" {
  description = "The name of an S3 bucket to create and use as a storage backend (if configured). Note: S3 bucket names must be *globally* unique."
  type        = string
  default     = "vault_storage"
}

variable "force_destroy_s3_bucket" {
  description = "If you set this to true, when you run terraform destroy, this tells Terraform to delete all the objects in the S3 bucket used for backend storage (if configured). You should NOT set this to true in production or you risk losing all your data! This property is only here so automated tests of this module can clean up after themselves."
  type        = bool
  default     = false
}
