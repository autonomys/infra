// Output Variables

output "ingress_rules" {
  value = aws_security_group.allow_runner.*.ingress
}

output "public_subnet_eip" {
  value = aws_eip.public_subnet_eip.*.public_ip
}

output "squid_blue_node_server_id" {
  value = aws_instance.squid_blue_node.*.id
}

output "squid_blue_node_public_ip" {
  value = aws_instance.squid_blue_node.*.public_ip
}

output "squid_blue_node_private_ip" {
  value = aws_instance.squid_blue_node.*.private_ip
}

output "squid_blue_node_ami" {
  value = aws_instance.squid_blue_node.*.ami
}


output "squid_green_node_server_id" {
  value = aws_instance.squid_green_node.*.id
}

output "squid_green_node_private_ip" {
  value = aws_instance.squid_green_node.*.private_ip
}

output "squid_green_node_public_ip" {
  value = aws_instance.squid_green_node.*.public_ip
}

output "squid_green_node_ami" {
  value = aws_instance.squid_green_node.*.ami
}

output "archive_node_server_id" {
  value = aws_instance.archive_node.*.id
}

output "archive_node_private_ip" {
  value = aws_instance.archive_node.*.private_ip
}

output "archive_node_public_ip" {
  value = aws_instance.archive_node.*.public_ip
}

output "archive_node_ami" {
  value = aws_instance.archive_node.*.ami
}

output "dns-records" {
  value = [
    cloudflare_record.squid[*].hostname,
    cloudflare_record.archive[*].hostname,
  ]
}
