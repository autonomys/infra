output "rpc_us_record" {
  value = cloudflare_record.rpc-0.*.hostname
}

output "rpc_eu_record" {
  value = cloudflare_record.rpc-1.*.hostname
}

output "evm_us_record" {
  value = cloudflare_record.evm-0.*.hostname
}

output "evm_eu_record" {
  value = cloudflare_record.evm-1.*.hostname
}

output "rpc_load_balancer" {
  value = cloudflare_load_balancer.rpc-lb.name
}

output "evm_load_balancer" {
  value = cloudflare_load_balancer.evm-lb.name
}
