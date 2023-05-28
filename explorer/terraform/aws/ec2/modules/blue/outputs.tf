output "squid-node-blue-ipv4-addresses" {
  value       = module.blue.squid_blue_node.*.public_ip
  description = "Explorer node IPv4 Addresses"
}

output "archive-node-ipv4-addresses" {
  value       = aws_instance.archive_node.*.public_ip
  description = "Explorer node IPv4 Addresses"
}

output "dns-records-blue" {
  value       = module.blue.dns-records
  description = "DNS records"
}
