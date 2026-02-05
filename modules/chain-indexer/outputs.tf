output "chain_indexer_public_ip" {
  value = aws_instance.chain_indexer_node.public_ip
}

output "dns_record" {
  value = format("%s.%s", trimsuffix(cloudflare_dns_record.indexer_dns.name, ".${data.cloudflare_zone.cloudflare_zone.name}"), data.cloudflare_zone.cloudflare_zone.name)
}
