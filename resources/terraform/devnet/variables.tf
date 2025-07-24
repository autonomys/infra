variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  type        = string
  description = "Availability Zones"
  default     = "us-east-1a"
}

variable "disk_volume_size" {
  type    = number
  default = 100
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
  type = string
}

variable "ssh_agent_identity" {
  type = string
}

variable "nr_api_key" {
  description = "New relic API Key"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare api token"
  sensitive   = true
}
