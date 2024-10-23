//output
output "rpc-indexer-node-ipv4-addresses" {
  value       = module.taurus.rpc-indexer_node_public_ip
  description = "RPC indexer node IPv4 Addresses"
}

output "nova-indexer-node-ipv4-addresses" {
  value       = module.taurus.nova-indexer_node_public_ip
  description = "Nova indexer node IPv4 Addresses"
}

output "farmer-node-ipv4-addresses" {
  value       = module.taurus.farmer_node_public_ip
  description = "Farmer node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = module.taurus.bootstrap_node_public_ip
  description = "Bootstrap node IPv4 Addresses"
}

output "bootstrap-node-evm-ipv4-addresses" {
  value       = module.taurus.bootstrap_node_evm_public_ip
  description = "EVM Bootstrap node IPv4 Addresses"
}

output "bootstrap-node-autoid-ipv4-addresses" {
  value       = module.taurus.bootstrap_node_autoid_public_ip
  description = "AutoID Bootstrap node IPv4 Addresses"
}

output "domain-node-ipv4-addresses" {
  value       = module.taurus.domain_node_public_ip
  description = "Domain node IPv4 Addresses"
}

output "autoid-node-ipv4-addresses" {
  value       = module.taurus.autoid_node_public_ip
  description = "AutoID node IPv4 Addresses"
}

output "rpc-node-ipv4-addresses" {
  value       = module.taurus.rpc_node_public_ip
  description = "RPC node IPv4 Addresses"
}

output "pot_external_entropy" {
  value       = var.pot_external_entropy
  description = "Pot external entropy"

}
