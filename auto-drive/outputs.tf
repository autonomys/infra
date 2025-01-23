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
  value       = aws_eip.auto_drive_eip[*].public_ip
}

output "gateway_eip" {
  description = "Elastic IPs for Gateway instances"
  value       = aws_eip.gateway_eip[*].public_ip
}
