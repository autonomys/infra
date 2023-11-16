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

output "nova_squid_blue_node_server_id" {
  value = aws_instance.nova_squid_blue_node.*.id
}

output "nova_squid_blue_node_public_ip" {
  value = aws_instance.nova_squid_blue_node.*.public_ip
}

output "nova_squid_blue_node_private_ip" {
  value = aws_instance.nova_squid_blue_node.*.private_ip
}

output "nova_squid_blue_node_ami" {
  value = aws_instance.nova_squid_blue_node.*.ami
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

output "nova_squid_green_node_server_id" {
  value = aws_instance.nova_squid_green_node.*.id
}

output "nova_squid_green_node_private_ip" {
  value = aws_instance.nova_squid_green_node.*.private_ip
}

output "nova_squid_green_node_public_ip" {
  value = aws_instance.nova_squid_green_node.*.public_ip
}

output "nova_squid_green_node_ami" {
  value = aws_instance.nova_squid_green_node.*.ami
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

output "nova_archive_node_server_id" {
  value = aws_instance.nova_archive_node.*.id
}

output "nova_archive_node_private_ip" {
  value = aws_instance.nova_archive_node.*.private_ip
}

output "nova_archive_node_public_ip" {
  value = aws_instance.nova_archive_node.*.public_ip
}

output "nova_archive_node_ami" {
  value = aws_instance.nova_archive_node.*.ami
}

output "nova_blockscout_node_public_ip" {
  value = aws_instance.blockscout_node.*.public_ip
}

output "dns-records" {
  value = [
    cloudflare_record.squid-blue[*].hostname,
    cloudflare_record.squid-green[*].hostname,
    cloudflare_record.archive[*].hostname,
    cloudflare_record.nova-squid-blue[*].hostname,
    cloudflare_record.nova-squid-green[*].hostname,
    cloudflare_record.nova-archive[*].hostname,
    cloudflare_record.nova[*].hostname,
  ]
}
