data "cloudflare_zone" "cloudflare_zone" {
  filter = {
    name = var.instance.domain_fqdn
  }
}

resource "cloudflare_dns_record" "indexer_dns" {
  depends_on = [aws_instance.chain_indexer_node]
  zone_id    = data.cloudflare_zone.cloudflare_zone.zone_id
  name       = "indexer.${var.instance.network_name}.${data.cloudflare_zone.cloudflare_zone.name}"
  content    = aws_instance.chain_indexer_node.public_ip
  type       = "A"
  ttl        = 1
  proxied    = true
}
