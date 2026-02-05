output "chain_indexer_public_ip" {
  value       = module.mainnet_chain_indexer.chain_indexer_public_ip
  description = "Chain Indexer public IP"
}

output "chain_indexer_dns_record" {
  value       = module.mainnet_chain_indexer.dns_record
  description = "Chain Indexer DNS record"
}
