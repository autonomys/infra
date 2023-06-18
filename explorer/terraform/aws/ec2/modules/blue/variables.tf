variable "datadog_api_key" {
  description = "Datadog API Key"
}

variable "cloudflare_email" {
  type        = string
  description = "cloudflare email address"
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
}

variable "network_name" {
  description = "Network name"
  type        = string
  default     = "gemini-3d"
}
variable "deployment_color" {
  description = "Deployment environment"
  type        = string
  default     = "blue"
}

variable "instance_type" {
  default = "m6a.2xlarge"
  type    = string
}

variable "vpc_id" {
  default = "default"
  type    = string
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-2c"]
}

variable "instance_count_blue" {
  type    = number
  default = 1
}

variable "instance_count_green" {
  type    = number
  default = 0
}

variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-2"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.3.0/24"]
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
  default = "explorer-deployer"
  type    = string
}

variable "ssh_user" {
  default = "ubuntu"
  type    = string
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/explorer-deployer.pem"
}

variable "disk_volume_size" {
  type    = number
  default = 800
}

variable "disk_volume_type" {
  type    = string
  default = "gp3"
}
