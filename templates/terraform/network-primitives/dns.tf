data "cloudflare_zone" "cloudflare_zone" {
  zone_id = var.cloudflare_zone_id
}


locals {
  # Calculate the split point
  instance_split = var.domain-node-config.instance-count / 2

  # Create explicit mappings for auto_evm and autoid instances
  auto_evm_instances = {
    for idx in range(0, local.instance_split) : idx => {
      ip_v4 = local.evm_nodes_ip_v4[idx]
      ip_v6 = local.evm_nodes_ip_v6[idx]
    }
  }

  autoid_instances = {
    for idx in range(0, local.instance_split) : idx => {
      ip_v4 = local.autoid_nodes_ip_v4[idx]
      ip_v6 = local.autoid_nodes_ip_v6[idx]
    }
  }
}

resource "cloudflare_dns_record" "rpc" {
  count   = length(local.rpc_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.rpc-node-config.domain-prefix}-${count.index}.${var.network_name}"
  content = local.rpc_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_dns_record" "auto_evm" {
  for_each = local.auto_evm_instances
  zone_id  = var.cloudflare_zone_id
  name     = "${var.domain-node-config.domain-prefix[0]}-${each.key}.${var.network_name}"
  content  = each.value.ip_v4
  type     = "A"
  ttl      = 3600
}

resource "cloudflare_dns_record" "auto_evm_ipv6" {
  for_each = local.auto_evm_instances
  zone_id  = var.cloudflare_zone_id
  name     = "${var.domain-node-config.domain-prefix[0]}-${each.key}.${var.network_name}"
  content  = each.value.ip_v6
  type     = "AAAA"
  ttl      = 3600
}

resource "cloudflare_dns_record" "rpc-indexer" {
  count   = length(local.rpc_indexer_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.rpc-indexer-node-config.domain-prefix}-${count.index}.${var.network_name}"
  content = local.rpc_indexer_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_dns_record" "auto-evm-indexer-rpc" {
  count   = length(local.auto_evm_indexer_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.auto-evm-indexer-node-config.domain-prefix}-${count.index}.${var.network_name}"
  content = local.auto_evm_indexer_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_dns_record" "autoid" {
  for_each = local.autoid_instances
  zone_id  = var.cloudflare_zone_id
  name     = "${var.domain-node-config.domain-prefix[1]}-${each.key}.${var.network_name}"
  content  = each.value.ip_v4
  type     = "A"
  ttl      = 3600
}

resource "cloudflare_dns_record" "autoid_ipv6" {
  for_each = local.autoid_instances
  zone_id  = var.cloudflare_zone_id
  name     = "${var.domain-node-config.domain-prefix[1]}-${each.key}.${var.network_name}"
  content  = each.value.ip_v6
  type     = "AAAA"
  ttl      = 3600
}

resource "cloudflare_dns_record" "bootstrap" {
  count   = length(local.bootstrap_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.network_name}"
  content = local.bootstrap_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_dns_record" "bootstrap_ipv6" {
  count   = length(local.bootstrap_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.network_name}"
  content = local.bootstrap_nodes_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 3600
}

resource "cloudflare_dns_record" "bootstrap_evm" {
  count   = length(local.bootstrap_nodes_evm_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.domain-node-config.domain-prefix[0]}.${var.network_name}"
  content = local.bootstrap_nodes_evm_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_dns_record" "bootstrap_evm_ipv6" {
  count   = length(local.bootstrap_nodes_evm_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.domain-node-config.domain-prefix[0]}.${var.network_name}"
  content = local.bootstrap_nodes_evm_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 3600
}

resource "cloudflare_dns_record" "bootstrap_auto" {
  count   = length(local.bootstrap_nodes_autoid_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.domain-node-config.domain-prefix[1]}.${var.network_name}"
  content = local.bootstrap_nodes_autoid_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_dns_record" "bootstrap_auto_ipv6" {
  count   = length(local.bootstrap_nodes_autoid_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.domain-node-config.domain-prefix[1]}.${var.network_name}"
  content = local.bootstrap_nodes_autoid_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 3600
}
