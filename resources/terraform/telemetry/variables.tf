variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "availability_zone" {
  type    = string
  default = "us-west-2c"
}

variable "vpc_cidr_block" {
  type    = string
  default = "172.31.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "172.31.1.0/24"
}

variable "instance_type" {
  type    = string
  default = "m7a.xlarge"
}

variable "disk_volume_size" {
  type    = number
  default = 200
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}

variable "aws_key_name" {
  type    = string
  default = "deployer"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
