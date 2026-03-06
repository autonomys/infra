################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

################################################################################
# RabbitMQ Outputs
################################################################################

output "rabbitmq_primary_endpoint" {
  description = "Primary RabbitMQ broker endpoint"
  value       = aws_mq_broker.rabbitmq_broker_primary.instances[0].endpoints[0]
}

output "rabbitmq_instance_type" {
  description = "Instance type for RabbitMQ broker instances"
  value       = var.rabbitmq.instance_type
}

