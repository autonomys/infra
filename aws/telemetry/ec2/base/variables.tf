variable "instance_type" {
  type    = string
}

variable "vpc_id" {
  type    = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "azs" {
  type        = string
  description = "Availability Zones"
  default     = "us-west-2a"
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
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
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

variable "path_to_scripts" {
  description = "Path to the scripts"
  type        = string
}

variable "path_to_configs" {
  description = "Path to the configs"
  type        = string
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "telemetry-subspace-node-config" {
  description = "telemetry node deployment config"
  type = object({
    domain-prefix      = string
    instance-type      = string
    deployment-version = number
    regions            = string
    instance-count     = number
    disk-volume-size   = number
    disk-volume-type   = string
  })
}

variable "cloudflare_email" {
  type        = string
  description = "cloudflare email address"
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
}
