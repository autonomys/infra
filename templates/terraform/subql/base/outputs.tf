// Output Variables

output "ingress_rules" {
  value = aws_security_group.gemini-subql-sg.*.ingress
}

output "subql_blue_node_server_id" {
  value = aws_instance.subql_blue_node.*.id
}

output "subql_blue_node_public_ip" {
  value = aws_instance.subql_blue_node.*.public_ip
}

output "subql_blue_node_private_ip" {
  value = aws_instance.subql_blue_node.*.private_ip
}

output "subql_blue_node_ami" {
  value = aws_instance.subql_blue_node.*.ami
}

output "nova_subql_blue_node_server_id" {
  value = aws_instance.nova_subql_blue_node.*.id
}

output "nova_subql_blue_node_public_ip" {
  value = aws_instance.nova_subql_blue_node.*.public_ip
}

output "nova_subql_blue_node_private_ip" {
  value = aws_instance.nova_subql_blue_node.*.private_ip
}

output "nova_subql_blue_node_ami" {
  value = aws_instance.nova_subql_blue_node.*.ami
}


output "subql_green_node_server_id" {
  value = aws_instance.subql_green_node.*.id
}

output "subql_green_node_private_ip" {
  value = aws_instance.subql_green_node.*.private_ip
}

output "subql_green_node_public_ip" {
  value = aws_instance.subql_green_node.*.public_ip
}

output "subql_green_node_ami" {
  value = aws_instance.subql_green_node.*.ami
}

output "nova_subql_green_node_server_id" {
  value = aws_instance.nova_subql_green_node.*.id
}

output "nova_subql_green_node_private_ip" {
  value = aws_instance.nova_subql_green_node.*.private_ip
}

output "nova_subql_green_node_public_ip" {
  value = aws_instance.nova_subql_green_node.*.public_ip
}

output "nova_subql_green_node_ami" {
  value = aws_instance.nova_subql_green_node.*.ami
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
    cloudflare_record.subql-blue[*].hostname,
    cloudflare_record.subql-green[*].hostname,
    cloudflare_record.subql-live[*].hostname,
    cloudflare_record.archive[*].hostname,
    cloudflare_record.nova-subql-blue[*].hostname,
    cloudflare_record.nova-subql-green[*].hostname,
    cloudflare_record.nova-subql-live[*].hostname,
    cloudflare_record.nova-archive[*].hostname,
    cloudflare_record.nova[*].hostname,
  ]
}
