output "do-full-node-ipv4-addresses" {
  value       = digitalocean_droplet.gemini-2a-full-nodes[*].ipv4_address
  description = "DO full node IPv4 Addresses"
}

output "do-bootstrap-node-ipv4-addresses" {
  value       = digitalocean_droplet.gemini-2a-bootstrap-nodes[*].ipv4_address
  description = "DO Bootstrap node IPv4 Addresses"
}

output "hetzner-bootstrap-node-ipv4-addresses" {
  value       = var.hetzner_bootstrap_node_ips
  description = "Hetzner Bootstrap node IPv4 Addresses"
}

output "hetzner-full-node-ipv4-addresses" {
  value       = var.hetzner_full_node_ips
  description = "Hetzner full node IPv4 Addresses"
}

output "hetzner-rpc-node-ipv4-addresses" {
  value       = var.hetzner_rpc_node_ips
  description = "Hetzner rpc node IPv4 Addresses"
}

output "rpc-records" {
  value = cloudflare_record.rpc[*].hostname
}
