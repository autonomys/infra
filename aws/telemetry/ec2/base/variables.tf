variable "instance_type" {
  default = ["t2.micro"]
  type    = list(string)
}

variable "vpc_id" {
  default = "default"
  type    = string
}

variable "azs" {
  type        = string
  description = "Availability Zones"
  default     = "us-east-1c"
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

variable "disk_volume_size" {
  type    = number
  default = 50
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
  default   = "deployer"
  type      = string
  sensitive = true
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/deployer.pem"
}

variable "network_name" {
  description = "Network name"
  type        = string
}

variable "path_to_scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "telemetry-subspace-node-config" {
  description = "node configuration"
  type = object({
    network-name       = string
    domain-prefix      = string
    instance-type      = string
    deployment-version = number
    regions            = list(string)
    instance-count     = number
    disk-volume-size   = number
    disk-volume-type   = string
  })
}
