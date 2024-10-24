data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "subql-blue" {
  count   = var.blue-subql-node-config.instance-count-blue > 0 ? var.blue-subql-node-config.instance-count-blue : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.blue-subql-node-config.domain-prefix}.${var.blue-subql-node-config.network-name}"
  value   = local.blue_subql_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "subql-green" {
  count   = var.green-subql-node-config.instance-count-green > 0 ? var.green-subql-node-config.instance-count-green : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.green-subql-node-config.domain-prefix}.${var.green-subql-node-config.network-name}"
  value   = local.green_subql_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "subql-live" {
  count   = var.blue-subql-node-config.instance-count-blue > 0 ? var.blue-subql-node-config.instance-count-blue : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "subql.${var.network_name}"
  value   = local.blue_subql_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "nova-subql-blue" {
  count   = var.nova-blue-subql-node-config.instance-count-blue > 0 ? var.nova-blue-subql-node-config.instance-count-blue : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.nova-blue-subql-node-config.domain-prefix}.subql.${var.network_name}"
  value   = local.nova_blue_subql_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "nova-subql-green" {
  count   = var.nova-green-subql-node-config.instance-count-green > 0 ? var.nova-green-subql-node-config.instance-count-green : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.nova-green-subql-node-config.domain-prefix}.subql.${var.network_name}"
  value   = local.nova_green_subql_node_ip_v4[count.index]
  type    = "A"
  ttl     = "3600"
}

resource "cloudflare_record" "nova-subql-live" {
  count   = var.nova-blue-subql-node-config.instance-count-blue > 0 ? var.nova-blue-subql-node-config.instance-count-blue : 0
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "nova.subql.${var.network_name}"
  value   = local.nova_blue_subql_node_ip_v4[count.index]
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
