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
  sensitive   = true
}

################################################################################
# EC2 Backend Outputs
################################################################################

output "ec2_auto_drive_ids" {
  description = "The IDs of the auto-drive instances"
  value       = module.auto_drive.ec2_backend_ids
}

output "ec2_auto_drive_arns" {
  description = "The ARNs of the auto-drive instances"
  value       = module.auto_drive.ec2_backend_arns
}

output "ec2_auto_drive_instance_states" {
  description = "The states of the auto-drive instances"
  value       = module.auto_drive.ec2_backend_instance_states
}

output "ec2_auto_drive_private_ips" {
  description = "The private IPs of the auto-drive instances"
  value       = module.auto_drive.ec2_backend_private_ips
}

output "ec2_auto_drive_public_ips" {
  description = "The public IPs of the auto-drive instances"
  value       = module.auto_drive.ec2_backend_public_ips
}

output "ec2_auto_drive_availability_zones" {
  description = "The availability zones of the auto-drive instances"
  value       = module.auto_drive.ec2_backend_availability_zones
}

################################################################################
# EC2 Gateway Outputs
################################################################################

output "ec2_gateway_ids" {
  description = "The IDs of the gateway instances"
  value       = module.auto_drive.ec2_gateway_ids
}

output "ec2_gateway_arns" {
  description = "The ARNs of the gateway instances"
  value       = module.auto_drive.ec2_gateway_arns
}

output "ec2_gateway_instance_states" {
  description = "The states of the gateway instances"
  value       = module.auto_drive.ec2_gateway_instance_states
}

output "ec2_gateway_private_ips" {
  description = "The private IPs of the gateway instances"
  value       = module.auto_drive.ec2_gateway_private_ips
}

output "ec2_gateway_public_ips" {
  description = "The public IPs of the gateway instances"
  value       = module.auto_drive.ec2_gateway_public_ips
}

output "ec2_gateway_availability_zones" {
  description = "The availability zones of the gateway instances"
  value       = module.auto_drive.ec2_gateway_availability_zones
}

output "auto_drive_eip" {
  description = "Elastic IPs for Auto-Drive instances"
  value       = module.auto_drive.ec2_backend_public_ips
}

output "gateway_eip" {
  description = "Elastic IPs for Gateway instances"
  value       = module.auto_drive.ec2_gateway_public_ips
}

################################################################################
# RDS Outputs
################################################################################

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.auto_drive.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.auto_drive.db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.auto_drive.db_instance_availability_zone
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.auto_drive.db_instance_endpoint
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.auto_drive.db_instance_engine
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database"
  value       = module.auto_drive.db_instance_engine_version_actual
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance"
  value       = module.auto_drive.db_instance_hosted_zone_id
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.auto_drive.db_instance_identifier
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.auto_drive.db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.auto_drive.db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = module.auto_drive.db_instance_name
}

output "db_instance_port" {
  description = "The database port"
  value       = module.auto_drive.db_instance_port
}

################################################################################
# Auth Lambda Outputs
################################################################################

output "auth_api_gateway_url" {
  description = "Auth HTTP API Gateway invoke URL — set this as AUTH_SERVICE_URL after cutover"
  value       = aws_apigatewayv2_stage.auth_default.invoke_url
}

output "auth_lambda_function_name" {
  description = "Auth Lambda function name (pass to aws lambda update-function-code after each build)"
  value       = aws_lambda_function.auth.function_name
}

output "auth_lambda_function_arn" {
  description = "Auth Lambda function ARN"
  value       = aws_lambda_function.auth.arn
}

output "auth_lambda_role_arn" {
  description = "Auth Lambda IAM execution role ARN"
  value       = aws_iam_role.auth_lambda.arn
}
