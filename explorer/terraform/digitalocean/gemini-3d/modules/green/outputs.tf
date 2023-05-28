output "do-squid-node-green-ipv4-addresses" {
  value       = module.green.do-squid-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "do-archive-node-green-ipv4-addresses" {
  value       = module.green.do-archive-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "dns-records-green" {
  value       = module.green.dns-records
  description = "DNS records"
}
