variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
}

variable "region" {
  description = "AWS region for primary resources"
  type        = string
}

variable "backup_region" {
  description = "AWS region for RDS backup replication"
  type        = string
  default     = ""
}

variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr            = string
    private_subnets = list(string)
    public_subnets  = list(string)
    az_count        = number
  })
}

variable "rabbitmq" {
  description = "RabbitMQ broker configuration"
  type = object({
    instance_type   = string
    version         = string
    deployment_mode = string
    username        = string
  })
  sensitive = true
}

variable "instances" {
  description = "EC2 instance configuration"
  type = object({
    backend_count         = number
    backend_instance_type = string
    backend_names         = optional(list(string), [])
    gateway_count         = number
    gateway_instance_type = string
    gateway_names         = optional(list(string), [])
    backend_volume_size   = number
    gateway_volume_size   = number
  })
}

variable "database" {
  description = "RDS PostgreSQL configuration"
  type = object({
    instance_class    = string
    engine_version    = string
    allocated_storage = number
    max_storage       = number
    multi_az          = bool
  })
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
