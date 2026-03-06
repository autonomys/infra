################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "The VPC ID"
  value       = module.auto_drive.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.auto_drive.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.auto_drive.public_subnets
}

################################################################################
# RabbitMQ Outputs
################################################################################

output "rabbitmq_primary_endpoint" {
  description = "Primary RabbitMQ broker endpoint"
  value       = module.auto_drive.rabbitmq_primary_endpoint
}

output "rabbitmq_instance_type" {
  description = "Instance type for RabbitMQ broker instances"
  value       = module.auto_drive.rabbitmq_instance_type
}
