data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "rpc" {
  count   = length(local.rpc_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.rpc-node-config.domain-prefix}-${count.index}.${var.network_name}"
  value   = local.rpc_nodes_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "nova" {
  count   = length(local.evm_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.evm-node-config.domain-prefix[0]}-${count.index}.${var.network_name}"
  value   = local.evm_nodes_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "nova_ipv6" {
  count   = length(local.evm_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.evm-node-config.domain-prefix[0]}-${count.index}.${var.network_name}"
  value   = local.evm_nodes_ip_v6[count.index]
  type    = "AAAA"
}

resource "cloudflare_record" "rpc-indexer" {
  count   = length(local.rpc_indexer_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.rpc-indexer-node-config.domain-prefix}-${count.index}.${var.network_name}"
  value   = local.rpc_indexer_nodes_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "nova-indexer-rpc" {
  count   = length(local.nova_indexer_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.nova-indexer-node-config.domain-prefix}-${count.index}.${var.network_name}"
  value   = local.nova_indexer_nodes_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "auto" {
  count   = length(local.evm_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.autoid-node-config.domain-prefix[1]}-${count.index}.${var.network_name}"
  value   = local.evm_nodes_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "auto_ipv6" {
  count   = length(local.evm_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.autoid-node-config.domain-prefix[1]}-${count.index}.${var.network_name}"
  value   = local.evm_nodes_ip_v6[count.index]
  type    = "AAAA"
}

resource "cloudflare_record" "bootstrap" {
  count   = length(local.bootstrap_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.${var.network_name}"
  value   = local.bootstrap_nodes_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "bootstrap_ipv6" {
  count   = length(local.bootstrap_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.${var.network_name}"
  value   = local.bootstrap_nodes_ip_v6[count.index]
  type    = "AAAA"
}

resource "cloudflare_record" "bootstrap_evm" {
  count   = length(local.bootstrap_nodes_evm_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.nova.${var.network_name}"
  value   = local.bootstrap_nodes_evm_ip_v6[count.index]
  type    = "A"
}

resource "cloudflare_record" "bootstrap_evm_ipv6" {
  count   = length(local.bootstrap_nodes_evm_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.nova.${var.network_name}"
  value   = local.bootstrap_nodes_evm_ip_v6[count.index]
  type    = "AAAA"
}

resource "cloudflare_record" "bootstrap_auto" {
  count   = length(local.bootstrap_nodes_autoid_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.auto.${var.network_name}"
  value   = local.bootstrap_nodes_autoid_ip_v6[count.index]
  type    = "A"
}

resource "cloudflare_record" "bootstrap_auto_ipv6" {
  count   = length(local.bootstrap_nodes_autoid_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.auto.${var.network_name}"
  value   = local.bootstrap_nodes_autoid_ip_v6[count.index]
  type    = "AAAA"
}
