data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "rpc" {
  count = length(local.rpc_node_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.rpc-node-config.domain-prefix}-${count.index}.${var.network-name}"
  value   = local.rpc_node_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "bootstrap" {
  count = length(local.bootstrap_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.${var.network-name}"
  value   = local.bootstrap_nodes_ip_v4[count.index]
  type    = "A"
}
