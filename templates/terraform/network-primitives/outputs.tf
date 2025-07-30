// Output Variables
output "consensus_bootstrap_node_public_ip" {
  value = aws_instance.consensus_bootstrap_nodes.*.public_ip
}

output "consensus_rpc_node_public_ip" {
  value = aws_instance.consensus_rpc_nodes.*.public_ip
}

output "consensus_farmer_node_public_ip" {
  value = aws_instance.consensus_farmer_nodes.*.public_ip
}

output "domain_bootstrap_node_public_ip" {
  value = aws_instance.domain_bootstrap_nodes.*.public_ip
}

output "domain_rpc_node_public_ip" {
  value = aws_instance.domain_rpc_nodes.*.public_ip
}

output "domain_operator_node_public_ip" {
  value = aws_instance.domain_operator_nodes.*.public_ip
}

output "dns-records" {
  value = concat(
    [for record in cloudflare_dns_record.consensus_bootstrap_ipv4 : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.consensus_rpc : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.domain_bootstrap_ipv4 : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.domain_rpc : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
  )
}
