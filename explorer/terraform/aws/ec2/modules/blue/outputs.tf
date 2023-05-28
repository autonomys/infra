output "squid-node-blue-ipv4-addresses" {
  value       = module.blue.squid-node-ipv4-addresses
  description = "Explorer node IPv4 Addresses"
}

output "archive-node-blue-ipv4-addresses" {
  value       = module.blue.archive-node-ipv4-addresses
  description = "Explorer node IPv4 Addresses"
}

output "dns-records-blue" {
  value       = module.blue.dns-records
  description = "DNS records"
}
