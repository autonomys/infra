variable "region" {
  description = "AWS region where the resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "backup_region" {
  description = "AWS region for RDS cross-region backup replication"
  type        = string
  default     = "us-west-1"
}

variable "rabbitmq_username" {
  description = "RabbitMQ username"
  type        = string
  default     = "guru"
  sensitive   = true
}
