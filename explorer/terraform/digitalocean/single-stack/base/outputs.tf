output "rpc-records" {
  value = [
    cloudflare_record.explorer[*].hostname,
    cloudflare_record.archive-squid[*].hostname,
  ]
}

output "do-explorer-node-ipv4-addresses" {
  value       = digitalocean_droplet.explorer-nodes[*].ipv4_address
  description = "DO full node IPv4 Addresses"
}

output "do-archive-squid-node-ipv4-addresses" {
  value       = digitalocean_droplet.archive-squid-nodes[*].ipv4_address
  description = "DO Farmer node IPv4 Addresses"
}
