data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "telemetry_subspace_node" {
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.domain_prefix}-new"
  value   = module.telemetry_subspace_node.public_ip
  type    = "A"
  ttl     = "3600"
}
