output "rpc-ipv4-address" {
  value       = digitalocean_droplet.x-net-rpc.ipv4_address
  description = "RPC IPV4 Address"
}

output "rpc-record" {
  value = cloudflare_record.x-net-rpc.hostname
}

output "farmer-ipv4-address" {
  value       = digitalocean_droplet.x-net-farmer.ipv4_address
  description = "Farmer IPV4 Address"
}

output "executor-ipv4-address" {
  value       = digitalocean_droplet.x-net-executor.ipv4_address
  description = "Executor IPV4 Address"
}
