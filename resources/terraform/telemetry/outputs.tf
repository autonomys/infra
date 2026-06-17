output "telemetry_instance_id" {
  value = aws_instance.telemetry.id
}

output "telemetry_public_ip" {
  value = aws_instance.telemetry.public_ip
}

output "telemetry_private_ip" {
  value = aws_instance.telemetry.private_ip
}
