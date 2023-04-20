output "do-explorer-node-green-ipv4-addresses" {
  value       = module.green.do-explorer-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "do-archive-squid-node-green-ipv4-addresses" {
  value       = module.green.do-archive-squid-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "dns-records-green" {
  value       = module.green.dns-records
  description = "DNS records"
}
