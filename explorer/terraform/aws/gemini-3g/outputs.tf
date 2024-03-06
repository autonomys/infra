output "squid-node-blue-ipv4-addresses" {
  value       = module.squids.squid_blue_node_public_ip
  description = "Squid blue node IPv4 Addresses"
}

output "squid-node-green-ipv4-addresses" {
  value       = module.squids.squid_green_node_public_ip
  description = "Squid green node IPv4 Addresses"
}

output "nova-squid-node-blue-ipv4-addresses" {
  value       = module.squids.nova_squid_blue_node_public_ip
  description = "Nova Squid blue node IPv4 Addresses"
}

output "nova-squid-node-green-ipv4-addresses" {
  value       = module.squids.nova_squid_green_node_public_ip
  description = "Nova Squid green node IPv4 Addresses"
}

output "archive-node-ipv4-addresses" {
  value       = module.squids.archive_node_public_ip
  description = "Archive node IPv4 Addresses"
}

output "nova-archive-node-ipv4-addresses" {
  value       = module.squids.nova_archive_node_public_ip
  description = "Nova Archive node IPv4 Addresses"
}

output "nova-blockscout-node-ipv4-addresses" {
  value       = module.squids.nova_blockscout_node_public_ip
  description = "Nova Blockscout IPv4 Addresses"
}

output "dns-records" {
  value       = module.squids.dns-records
  description = "DNS records"
}
