variable "gh_token" {
  default = ""
  type    = string
  sensitive = true
}

variable "netdata_token" {
  default = ""
  type    = string
  sensitive = true

}

variable "netdata_room" {
  default = ""
  type    = string
  sensitive = true

}

variable "gh_runner_version" {
  type = string
  default = ""
}

variable "gh_runner_checksums" {
  type = map(string)
  default = {
    linux_x86_64 = "",
    linux_arm64 = "",
    mac_x86_64 = "",
    mac_arm64 = "",
    windows_x86_64 = ""
  }
}

variable "instance_type" {
  default = ["t2.micro"]
  type    = list(string)
}

variable "instance_type_mac" {
  default = ["mac1.metal", "mac2.metal"]
  type    = list(string)
}

variable "instance_type_arm" {
  default = ["a1.2xlarge", "a1.4xlarge"]
  type    = list(string)
}

variable "vpc_id" {
  default = "default"
  type    = string
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-2a", "us-east-2b"]
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-1"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.1.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["172.31.2.0/24"]
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
  default   = "deployer"
  type      = string
  sensitive = true
}

variable "public_key_path" {
  type    = string
  default = ""
}

variable "win_admin_username" {
  default = "default"
  type    = string
  sensitive = true
}


variable "win_admin_password" {
  default = "default"
  type    = string
  sensitive = true
}
