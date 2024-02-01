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

# Remove system domain
# resource "cloudflare_record" "system-domain" {
#   count   = length(local.domain_node_ip_v4)
#   zone_id = data.cloudflare_zone.cloudflare_zone.id
#   name    = "${var.domain-node-config.domain-prefix}-${count.index}.system.${var.network_name}"
#   value   = local.domain_node_ip_v4[count.index]
#   type    = "A"
# }

resource "cloudflare_record" "core-domain" {
  count   = length(local.domain_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.domain-node-config.domain-prefix}.${var.network_name}"
  value   = local.domain_nodes_ip_v4[count.index]
  type    = "A"
}

resource "cloudflare_record" "core-domain_ipv6" {
  count   = length(local.domain_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.domain-node-config.domain-prefix}.${var.network_name}"
  value   = local.domain_nodes_ip_v6[count.index]
  type    = "AAAA"
}

resource "cloudflare_record" "nova" {
  count   = length(local.domain_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.domain-node-config.domain-prefix}-${count.index}.${var.network_name}"
  value   = local.domain_nodes_ip_v6[count.index]
  type    = "A"
}

resource "cloudflare_record" "nova_ipv6" {
  count   = length(local.domain_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "${var.domain-node-config.domain-prefix}-${count.index}.${var.network_name}"
  value   = local.domain_nodes_ip_v6[count.index]
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
