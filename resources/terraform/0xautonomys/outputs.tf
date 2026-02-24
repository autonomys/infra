output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Elastic IP address"
  value       = aws_eip.this.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}

output "instance_state" {
  description = "Current instance state"
  value       = aws_instance.this.instance_state
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.this.availability_zone
}
