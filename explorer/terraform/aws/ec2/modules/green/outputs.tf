output "squid-node-green-ipv4-addresses" {
  value       = module.green.squid_green_node_public_ip
  description = "Squid node IPv4 Addresses"
}

output "dns-records-green" {
  value       = module.green.dns-records
  description = "DNS records"
}
