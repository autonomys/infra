output "do-full-node-ipv4-addresses" {
  value       = digitalocean_droplet.full-nodes[*].ipv4_address
  description = "DO full node IPv4 Addresses"
}

output "do-farmer-node-ipv4-addresses" {
  value       = digitalocean_droplet.farmer-nodes[*].ipv4_address
  description = "DO Farmer node IPv4 Addresses"
}

output "do-bootstrap-node-ipv4-addresses" {
  value       = digitalocean_droplet.bootstrap-nodes[*].ipv4_address
  description = "DO Bootstrap node IPv4 Addresses"
}

output "do-rpc-node-ipv4-addresses" {
  value       = digitalocean_droplet.rpc-nodes[*].ipv4_address
  description = "DO RPC node IPv4 Addresses"
}

output "do-domain-node-ipv4-addresses" {
  value       = digitalocean_droplet.domain-nodes[*].ipv4_address
  description = "DO Domain node IPv4 Addresses"
}

output "rpc-records" {
  value = [
    cloudflare_record.bootstrap[*].hostname,
    cloudflare_record.rpc[*].hostname,
    cloudflare_record.system-domain-rpc[*].hostname,
    cloudflare_record.core-domain-rpc[*].hostname,
  ]
}
