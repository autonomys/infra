output "rpc-node-ipv4-addresses" {
  value       = digitalocean_droplet.gemini-2a-rpc-nodes[*].ipv4_address
  description = "RPC node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = digitalocean_droplet.gemini-2a-bootstrap-nodes[*].ipv4_address
  description = "Bootstrap node IPv4 Addresses"
}

output "rpc_records" {
  value = cloudflare_record.rpc[*].hostname
}
