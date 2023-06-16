output "squid-node-blue-ipv4-addresses" {
  value       = module.blue.squid_blue_node_public_ip
  description = "Squid blue node IPv4 Addresses"
}

output "dns-records-blue" {
  value       = module.blue.dns-records
  description = "DNS records"
}
