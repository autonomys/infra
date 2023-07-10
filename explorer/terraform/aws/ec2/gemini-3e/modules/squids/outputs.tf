output "squid-node-blue-ipv4-addresses" {
  value       = module.squids.squid_blue_node_public_ip
  description = "Squid blue node IPv4 Addresses"
}

output "squid-node-green-ipv4-addresses" {
  value       = module.squids.squid_green_node_public_ip
  description = "Squid blue node IPv4 Addresses"
}

output "dns-records-blue" {
  value       = module.squids.dns-records
  description = "DNS records"
}
