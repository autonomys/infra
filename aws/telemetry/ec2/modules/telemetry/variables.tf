variable "instance_type" {
  default = "m6a.4xlarge"
  type    = string
}

variable "vpc_id" {
  default = "telemetry-vpc"
  type    = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "azs" {
  type        = string
  description = "Availability Zones"
  default     = "us-west-2c"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "us-west-2"
}

variable "public_subnet_cidrs" {
  type        = string
  description = "Public Subnet CIDR values"
  default     = "172.31.1.0/24"
}

variable "disk_volume_size" {
  type = number
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "aws_key_name" {
  default = "deployer"
  type    = string
}

variable "ssh_user" {
  default = "ubuntu"
  type    = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/deployer.pem"
}

variable "cloudflare_email" {
  type        = string
  description = "cloudflare email address"
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
}
