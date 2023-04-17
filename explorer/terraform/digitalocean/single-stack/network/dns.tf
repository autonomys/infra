data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "explorer" {
  count   = length(local.explorer_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.explorer-node-config.domain-prefix}-${count.index}.${var.network-name}"
  value   = local.explorer_node_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "squid-archive" {
  count   = length(local.squid_archive_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.squid-archive-node-config.domain-prefix}-${count.index}.${var.network-name}"
  value   = local.squid_archive_node_ip_v4[count.index]
  type    = "A"
}
