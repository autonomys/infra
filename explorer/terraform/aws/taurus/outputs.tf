output "subql-node-blue-ipv4-addresses" {
  value       = module.subql.subql_blue_node_public_ip
  description = "subql blue node IPv4 Addresses"
}

output "subql-node-green-ipv4-addresses" {
  value       = module.subql.subql_green_node_public_ip
  description = "subql green node IPv4 Addresses"
}

output "nova-subql-node-blue-ipv4-addresses" {
  value       = module.subql.nova_subql_blue_node_public_ip
  description = "Nova subql blue node IPv4 Addresses"
}

output "nova-subql-node-green-ipv4-addresses" {
  value       = module.subql.nova_subql_green_node_public_ip
  description = "Nova subql green node IPv4 Addresses"
}

output "dns-records" {
  value       = module.subql.dns-records
  description = "DNS records"
}
