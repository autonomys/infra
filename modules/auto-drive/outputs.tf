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

################################################################################
# EC2 Backend Outputs
################################################################################

output "ec2_backend_ids" {
  description = "The IDs of the auto-drive backend instances"
  value       = module.ec2_backend[*].id
}

output "ec2_backend_arns" {
  description = "The ARNs of the auto-drive backend instances"
  value       = module.ec2_backend[*].arn
}

output "ec2_backend_instance_states" {
  description = "The states of the auto-drive backend instances"
  value       = module.ec2_backend[*].instance_state
}

output "ec2_backend_private_ips" {
  description = "The private IPs of the auto-drive backend instances"
  value       = module.ec2_backend[*].private_ip
}

output "ec2_backend_public_ips" {
  description = "The public IPs of the auto-drive backend instances"
  value       = module.ec2_backend[*].public_ip
}

output "ec2_backend_availability_zones" {
  description = "The availability zones of the auto-drive backend instances"
  value       = module.ec2_backend[*].availability_zone
}

################################################################################
# EC2 Taurus Outputs
################################################################################

output "ec2_taurus_ids" {
  description = "The IDs of the taurus backend instances"
  value       = module.ec2_taurus[*].id
}

output "ec2_taurus_arns" {
  description = "The ARNs of the taurus backend instances"
  value       = module.ec2_taurus[*].arn
}

output "ec2_taurus_instance_states" {
  description = "The states of the taurus backend instances"
  value       = module.ec2_taurus[*].instance_state
}

output "ec2_taurus_private_ips" {
  description = "The private IPs of the taurus backend instances"
  value       = module.ec2_taurus[*].private_ip
}

output "ec2_taurus_public_ips" {
  description = "The public IPs of the taurus backend instances"
  value       = module.ec2_taurus[*].public_ip
}

output "ec2_taurus_availability_zones" {
  description = "The availability zones of the taurus backend instances"
  value       = module.ec2_taurus[*].availability_zone
}

################################################################################
# EC2 Gateway Outputs
################################################################################

output "ec2_gateway_ids" {
  description = "The IDs of the gateway instances"
  value       = module.ec2_gateway[*].id
}

output "ec2_gateway_arns" {
  description = "The ARNs of the gateway instances"
  value       = module.ec2_gateway[*].arn
}

output "ec2_gateway_instance_states" {
  description = "The states of the gateway instances"
  value       = module.ec2_gateway[*].instance_state
}

output "ec2_gateway_private_ips" {
  description = "The private IPs of the gateway instances"
  value       = module.ec2_gateway[*].private_ip
}

output "ec2_gateway_public_ips" {
  description = "The public IPs of the gateway instances"
  value       = module.ec2_gateway[*].public_ip
}

output "ec2_gateway_availability_zones" {
  description = "The availability zones of the gateway instances"
  value       = module.ec2_gateway[*].availability_zone
}

################################################################################
# EC2 Multi-Network Gateway Outputs
################################################################################

output "ec2_multi_gateway_ids" {
  description = "The IDs of the multi-network gateway instances"
  value       = module.ec2_multi_gateway[*].id
}

output "ec2_multi_gateway_arns" {
  description = "The ARNs of the multi-network gateway instances"
  value       = module.ec2_multi_gateway[*].arn
}

output "ec2_multi_gateway_instance_states" {
  description = "The states of the multi-network gateway instances"
  value       = module.ec2_multi_gateway[*].instance_state
}

output "ec2_multi_gateway_private_ips" {
  description = "The private IPs of the multi-network gateway instances"
  value       = module.ec2_multi_gateway[*].private_ip
}

output "ec2_multi_gateway_public_ips" {
  description = "The public IPs of the multi-network gateway instances"
  value       = module.ec2_multi_gateway[*].public_ip
}

output "ec2_multi_gateway_availability_zones" {
  description = "The availability zones of the multi-network gateway instances"
  value       = module.ec2_multi_gateway[*].availability_zone
}

################################################################################
# RDS Outputs
################################################################################

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.db.db_instance_availability_zone
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db.db_instance_endpoint
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.db.db_instance_engine
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database"
  value       = module.db.db_instance_engine_version_actual
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance"
  value       = module.db.db_instance_hosted_zone_id
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.db.db_instance_identifier
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.db.db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.db.db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = module.db.db_instance_name
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db.db_instance_port
}
