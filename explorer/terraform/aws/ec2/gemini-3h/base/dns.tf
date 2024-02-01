data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "squid-blue" {
  count   = var.blue-squid-node-config.instance-count-blue > 0 ? var.blue-squid-node-config.instance-count-blue : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.blue-squid-node-config.domain-prefix}.${var.blue-squid-node-config.network-name}"
  value   = local.blue_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-green" {
  count   = var.green-squid-node-config.instance-count-green > 0 ? var.green-squid-node-config.instance-count-green : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.green-squid-node-config.domain-prefix}.${var.green-squid-node-config.network-name}"
  value   = local.green_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "squid-live" {
  count   = var.green-squid-node-config.instance-count-green > 0 ? var.green-squid-node-config.instance-count-green : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "squid.${var.network_name}"
  value   = local.green_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "nova-squid-blue" {
  count   = var.nova-blue-squid-node-config.instance-count-blue > 0 ? var.nova-blue-squid-node-config.instance-count-blue : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.nova-blue-squid-node-config.domain-prefix}.squid.${var.network_name}"
  value   = local.nova_blue_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "nova-squid-green" {
  count   = var.nova-green-squid-node-config.instance-count-green > 0 ? var.nova-green-squid-node-config.instance-count-green : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.nova-green-squid-node-config.domain-prefix}.squid.${var.network_name}"
  value   = local.nova_green_squid_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "nova" {
  count   = var.nova-blockscout-node-config.instance-count > 0 ? var.nova-blockscout-node-config.instance-count : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.nova-blockscout-node-config.domain-prefix}.${var.network_name}"
  value   = local.blockscout_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "archive" {
  count   = var.archive-node-config.instance-count > 0 ? var.archive-node-config.instance-count : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.archive-node-config.domain-prefix}.${var.network_name}"
  value   = local.archive_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "nova-archive" {
  count   = var.nova-archive-node-config.instance-count > 0 ? var.nova-archive-node-config.instance-count : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.nova-archive-node-config.domain-prefix}.${var.network_name}"
  value   = local.nova_archive_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}
