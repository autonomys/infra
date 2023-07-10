// Output Variables

output "ingress_rules" {
  value = aws_security_group.gemini-squid-sg.*.ingress
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
    cloudflare_record.squid-blue[*].hostname,
    cloudflare_record.squid-green[*].hostname,
    cloudflare_record.archive[*].hostname,
  ]
}
