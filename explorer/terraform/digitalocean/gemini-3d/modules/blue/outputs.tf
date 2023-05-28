output "do-squid-node-blue-ipv4-addresses" {
  value       = module.blue.do-squid-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "do-archive-node-blue-ipv4-addresses" {
  value       = module.blue.do-archive-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "dns-records-blue" {
  value       = module.blue.dns-records
  description = "DNS records"
}
