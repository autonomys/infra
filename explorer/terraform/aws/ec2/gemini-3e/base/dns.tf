data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "squid-blue" {
  count   = var.blue-squid-node-config.instance-count-blue
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.blue-squid-node-config.domain-prefix}.squid.${var.blue-squid-node-config.network-name}"
  value   = local.blue_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-green" {
  count   = var.green-squid-node-config.instance-count-green
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.green-squid-node-config.domain-prefix}.squid.${var.green-squid-node-config.network-name}"
  value   = local.green_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-main-blue" {
  count   = var.blue-squid-node-config.instance-count-blue
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "squid.${var.blue-squid-node-config.network-name}"
  value   = local.blue_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-main-green" {
  count   = var.green-squid-node-config.instance-count-green
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "squid.${var.green-squid-node-config.network-name}"
  value   = local.green_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-live" {
  count   = var.green-squid-node-config.instance-count-green
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "squid.${var.network-name}"
  value   = local.green_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-live-evm" {
  count   = var.green-squid-node-config.instance-count-green
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.green-squid-node-config.domain-prefix}-squid.${var.network-name}"
  value   = local.green_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "archive" {
  count   = length(local.archive_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "archive.${var.network_name}"
  value   = local.archive_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}
