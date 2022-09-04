output "do-full-node-ipv4-addresses" {
  value       = digitalocean_droplet.gemini-2a-full-nodes[*].ipv4_address
  description = "DO full node IPv4 Addresses"
}

output "do_bootstrap-node-ipv4-addresses" {
  value       = digitalocean_droplet.gemini-2a-bootstrap-nodes[*].ipv4_address
  description = "DO Bootstrap node IPv4 Addresses"
}

#output "rpc_records" {
#  value = cloudflare_record.rpc[*].hostname
#}
