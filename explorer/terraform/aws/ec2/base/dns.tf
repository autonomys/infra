data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "squid-blue" {
  count   = var.squid-node-config.instance-count-blue
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.squid-node-config.domain-prefix}.squid.${var.squid-node-config.network-name}"
  value   = local.squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-green" {
  count   = var.squid-node-config.instance-count-green
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.squid-node-config.domain-prefix}.squid.${var.squid-node-config.network-name}"
  value   = local.squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}


resource "cloudflare_record" "archive" {
  count   = length(local.archive_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.squid-node-config.domain-prefix}.archive.${var.network_name}"
  value   = local.archive_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}
