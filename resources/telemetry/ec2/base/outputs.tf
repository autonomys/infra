// Output Variables

output "telemetry_subspace_node_server_id" {
  value = aws_instance.telemetry_subspace_node.id
}

output "telemetry_subspace_node_public_ip" {
  value = aws_instance.telemetry_subspace_node.public_ip
}

output "telemetry_subspace_node_private_ip" {
  value = aws_instance.telemetry_subspace_node.private_ip
}

output "telemetry_subspace_node_ami" {
  value = aws_instance.telemetry_subspace_node.ami
}

output "dns-records" {
  value = [
    cloudflare_record.telemetry_subspace_node.hostname,
  ]
}
