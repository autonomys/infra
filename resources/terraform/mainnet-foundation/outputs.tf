output "bare-consensus-bootstrap-node-ipv4-addresses" {
  value       = module.mainnet_foundation.bare_consensus_bootstrap_node_public_ip
  description = "Bare Consensus bootstrap node IPv4 Addresses"
}

output "dns-records" {
  value       = module.mainnet_foundation.dns-records
  description = "DNS records"
}
