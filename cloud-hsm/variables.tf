
variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "hsm_type" {
  default = "hsm1.medium"
  type    = string
}

variable "vpc_id" {
  default = "cloud-hsm"
  type    = string
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-west-2"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-west-2a"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.1.0/26"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["172.31.2.0/26"]
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}

variable "aws_key_name" {
  default = "windows-deployer"
  type    = string
}

variable "ssh_user" {
  type = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/windows-deployer.pem"
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "access_key" {
  type      = string
  sensitive = true
}
