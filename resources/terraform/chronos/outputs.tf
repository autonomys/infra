output "consensus-bootstrap-node-ipv4-addresses" {
  value       = module.chronos.consensus_bootstrap_node_public_ip
  description = "Bootstrap node IPv4 Addresses"
}


output "bare-consensus-bootstrap-node-ipv4-addresses" {
  value       = module.chronos.bare_consensus_bootstrap_node_public_ip
  description = "Bare Bootstrap node IPv4 Addresses"
}

output "consensus-rpc-node-ipv4-addresses" {
  value       = module.chronos.consensus_rpc_node_public_ip
  description = "RPC node IPv4 Addresses"
}

output "farmer-node-ipv4-addresses" {
  value       = module.chronos.consensus_farmer_node_public_ip
  description = "Farmer node IPv4 Addresses"
}

output "timekeeper-node-ipv4-addresses" {
  value       = module.chronos.timekeeper_node_public_ip
  description = "Timekeeper node IPv4 addresses"
}

output "domain-bootstrap-node-ipv4-addresses" {
  value       = module.chronos.domain_bootstrap_node_public_ip
  description = "Domain Bootstrap node IPv4 Addresses"
}

output "domain-rpc-node-ipv4-addresses" {
  value       = module.chronos.domain_rpc_node_public_ip
  description = "Domain RPC node IPv4 Addresses"
}

output "domain-operator-node-ipv4-addresses" {
  value       = module.chronos.domain_operator_node_public_ip
  description = "Domain Operator node IPv4 Addresses"
}

output "dns-records" {
  value       = module.chronos.dns-records
  description = "DNS records"
}
