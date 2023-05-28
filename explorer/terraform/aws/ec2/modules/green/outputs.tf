output "squid-node-green-ipv4-addresses" {
  value       = module.green.squid-node-ipv4-addresses
  description = "Explorer node IPv4 Addresses"
}

output "archive-node-green-ipv4-addresses" {
  value       = module.green.archive-node-ipv4-addresses
  description = "Explorer node IPv4 Addresses"
}

output "dns-records-green" {
  value       = module.green.dns-records
  description = "DNS records"
}
