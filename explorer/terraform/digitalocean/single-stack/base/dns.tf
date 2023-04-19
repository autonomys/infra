data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "explorer" {
  count   = length(local.explorer_squid_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.explorer-node-config.domain-prefix}-${count.index}.${var.network-name}"
  value   = local.explorer_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "archive-squid" {
  count   = length(local.archive_squid_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.archive-squid-node-config.domain-prefix}-${count.index}.${var.network-name}"
  value   = local.archive_squid_node_ip_v4[count.index]
  type    = "A"
}
