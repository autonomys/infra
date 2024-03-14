data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "telemetry_subspace_node" {
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.telemetry-subspace-node-config.domain-prefix}-new"
  value   = aws_instance.telemetry_subspace_node.public_ip
  type    = "A"
  ttl     = "3600"
}
