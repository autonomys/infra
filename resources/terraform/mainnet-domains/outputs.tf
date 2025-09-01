output "domain-bootstrap-node-ipv4-addresses" {
  value       = module.mainnet_domains.domain_bootstrap_node_public_ip
  description = "Domain Bootstrap node IPv4 Addresses"
}

output "domain-rpc-node-ipv4-addresses" {
  value       = module.mainnet_domains.domain_rpc_node_public_ip
  description = "Domain RPC node IPv4 Addresses"
}

output "domain-operator-node-ipv4-addresses" {
  value       = module.mainnet_domains.domain_operator_node_public_ip
  description = "Domain Operator node IPv4 Addresses"
}

output "bare-domain-operator-node-ipv4-addresses" {
  value       = module.mainnet_domains.bare_domain_operator_node_public_ip
  description = "Bare Domain Operator node IPv4 Addresses"
}

output "dns-records" {
  value       = module.mainnet_domains.dns-records
  description = "DNS records"
}
