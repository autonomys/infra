data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "squid" {
  count   = length(local.squid_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.squid-node-config.domain-prefix}-${count.index}.${var.squid-node-config.network-name}"
  value   = local.squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "archive" {
  count   = length(local.archive_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.archive-node-config.domain-prefix}-${count.index}.${var.archive-node-config.network-name}"
  value   = local.archive_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}
