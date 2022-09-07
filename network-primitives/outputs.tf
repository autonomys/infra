output "do-full-node-ipv4-addresses" {
  value       = digitalocean_droplet.full-nodes[*].ipv4_address
  description = "DO full node IPv4 Addresses"
}

output "do-bootstrap-node-ipv4-addresses" {
  value       = digitalocean_droplet.bootstrap-nodes[*].ipv4_address
  description = "DO Bootstrap node IPv4 Addresses"
}

output "do-rpc-node-ipv4-addresses" {
  value       = digitalocean_droplet.rpc-nodes[*].ipv4_address
  description = "DO RPC node IPv4 Addresses"
}

output "rpc-records" {
  value = cloudflare_record.rpc[*].hostname
}
