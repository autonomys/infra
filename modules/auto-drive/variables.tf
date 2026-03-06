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
    backend_count                = number
    backend_instance_type        = string
    taurus_backend_count         = number
    taurus_backend_instance_type = string
    gateway_count                = number
    gateway_instance_type        = string
    multi_gateway_count          = number
    multi_gateway_instance_type  = string
    backend_volume_size          = number
    gateway_volume_size          = number
  })
  default = null
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
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
