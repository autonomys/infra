################################################################################
# Auto-Drive Instances Outputs
################################################################################

output "ec2_auto_drive_ids" {
  description = "The IDs of the auto-drive instances"
  value       = module.ec2_auto_drive[*].id
}

output "ec2_auto_drive_arns" {
  description = "The ARNs of the auto-drive instances"
  value       = module.ec2_auto_drive[*].arn
}

output "ec2_auto_drive_instance_states" {
  description = "The states of the auto-drive instances (e.g., pending, running, etc.)"
  value       = module.ec2_auto_drive[*].instance_state
}

output "ec2_auto_drive_private_ips" {
  description = "The private IPs of the auto-drive instances"
  value       = module.ec2_auto_drive[*].private_ip
}

output "ec2_auto_drive_public_ips" {
  description = "The public IPs of the auto-drive instances, if applicable"
  value       = module.ec2_auto_drive[*].public_ip
}

output "ec2_auto_drive_availability_zones" {
  description = "The availability zones of the auto-drive instances"
  value       = module.ec2_auto_drive[*].availability_zone
}

################################################################################
# Gateway Instances Outputs
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
  description = "The states of the gateway instances (e.g., pending, running, etc.)"
  value       = module.ec2_gateway[*].instance_state
}

output "ec2_gateway_private_ips" {
  description = "The private IPs of the gateway instances"
  value       = module.ec2_gateway[*].private_ip
}

output "ec2_gateway_public_ips" {
  description = "The public IPs of the gateway instances, if applicable"
  value       = module.ec2_gateway[*].public_ip
}

output "ec2_gateway_availability_zones" {
  description = "The availability zones of the gateway instances"
  value       = module.ec2_gateway[*].availability_zone
}

output "auto_drive_eip" {
  description = "Elastic IPs for Auto-Drive instances"
  value       = module.ec2_auto_drive[*].public_ip
}

output "gateway_eip" {
  description = "Elastic IPs for Gateway instances"
  value       = module.ec2_gateway[*].public_ip
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
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
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

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db.db_instance_port
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.db.db_subnet_group_id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = module.db.db_subnet_group_arn
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = module.db.db_parameter_group_id
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = module.db.db_parameter_group_arn
}

output "db_enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the monitoring role"
  value       = module.db.enhanced_monitoring_iam_role_arn
}

output "db_instance_cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes"
  value       = module.db.db_instance_cloudwatch_log_groups
}

output "db_instance_master_user_secret_arn" {
  description = "The ARN of the master user secret (Only available when manage_master_user_password is set to true)"
  value       = module.db.db_instance_master_user_secret_arn
}

output "db_instance_secretsmanager_secret_rotation_enabled" {
  description = "Specifies whether automatic rotation is enabled for the secret"
  value       = module.db.db_instance_secretsmanager_secret_rotation_enabled
}

# RabbitMQ Broker Outputs
output "rabbitmq_primary_endpoint" {
  description = "Primary RabbitMQ broker endpoint"
  value       = aws_mq_broker.rabbitmq_broker_primary.instances[0].endpoints[0]
}

# Data replication is only supported for activemq engine currently.
# output "rabbitmq_secondary_endpoint" {
#   description = "Secondary RabbitMQ broker endpoint"
#   value       = aws_mq_broker.rabbitmq_broker_secondary.instances[0].endpoints[0]
# }

output "rabbitmq_instance_type" {
  description = "Instance type for RabbitMQ broker instances"
  value       = var.rabbitmq_instance_type
}

output "rabbitmq_username" {
  description = "RabbitMQ username"
  value       = var.rabbitmq_username
  sensitive   = true
}

output "rabbitmq_replication_username" {
  description = "RabbitMQ replication username"
  value       = var.rabbitmq_replication_username
  sensitive   = true
}

output "rabbitmq_password" {
  description = "RabbitMQ password"
  value       = random_password.rabbitmq_password.result
  sensitive   = true
}
