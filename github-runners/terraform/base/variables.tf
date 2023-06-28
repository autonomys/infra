variable "gh_token" {
  type      = string
  sensitive = true
}

variable "netdata_token" {
  type      = string
  sensitive = true

}

variable "netdata_room" {
  type      = string
  sensitive = true

}

variable "gh_runner_version" {
  type    = string
  default = "2.305.0"
}

variable "gh_runner_checksums" {
  type = map(string)
  default = {
    linux_x86_64   = "737bdcef6287a11672d6a5a752d70a7c96b4934de512b7eb283be6f51a563f2f",
    linux_arm64    = "63d7b0ba495055e390ac057dc67d721ed78113990fa837a20b141a75044e152a",
    mac_x86_64     = "a7c623e013f97db6c73c27288047c1d02ab6964519020ad0e87e69c328e96534",
    mac_arm64      = "a2383a869b99793dee5e1ff7c1df4e7bc86f73521ae03f884f0c7aa43830e2cb",
    windows_x86_64 = "3a4afe6d9056c7c63ecc17f4db32148e946454f2384427b0a4565b7690ef7420"
  }
}

variable "instance_type" {
  default = ["t3.2xlarge"]
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
  default     = ["us-east-2b", "us-east-1a"]
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-2"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.1.0/24"]
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "ssh_user" {
  type = list(string)
  default = [ "ubuntu", "ec2-user"]
  
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

variable "private_key_path" {
  type    = string
}

variable "win_admin_username" {
  type      = string
  default = "Administrator"
}


variable "win_admin_password" {
  type      = string
  sensitive = true
}
