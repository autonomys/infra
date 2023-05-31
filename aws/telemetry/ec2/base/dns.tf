data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "telemetry_subspace_node" {
  count   = length(local.telemetry_subspace_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.telemetry-subspace-node-config.domain-prefix}-${count.index}.${var.telemetry-subspace-node-config.network-name}"
  value   = local.telemetry_subspace_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}
