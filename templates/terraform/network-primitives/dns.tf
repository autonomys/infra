data "cloudflare_zone" "cloudflare_zone" {
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "rpc" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.rpc_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.rpc-node-config.dns-prefix}-${count.index}.${var.network_name}"
  content = local.rpc_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "auto_evm" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.evm_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.auto-evm-domain-node-config.domain-prefix}-${count.index}.${var.network_name}"
  content = local.evm_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "auto_evm_ipv6" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.evm_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.auto-evm-domain-node-config.domain-prefix}-${count.index}.${var.network_name}"
  content = local.evm_nodes_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "autoid" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.autoid_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.auto-id-domain-node-config.domain-prefix}-${count.index}.${var.network_name}"
  content = local.autoid_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "autoid_ipv6" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.autoid_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "${var.auto-id-domain-node-config.domain-prefix}-${count.index}.${var.network_name}"
  content = local.autoid_nodes_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "bootstrap" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.bootstrap_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.network_name}"
  content = local.bootstrap_nodes_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "bootstrap_ipv6" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.bootstrap_nodes_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.network_name}"
  content = local.bootstrap_nodes_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "bootstrap_evm" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.bootstrap_nodes_evm_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.auto-evm-domain-node-config.domain-prefix}.${var.network_name}"
  content = local.bootstrap_nodes_evm_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "bootstrap_evm_ipv6" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.bootstrap_nodes_evm_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.auto-evm-domain-node-config.domain-prefix}.${var.network_name}"
  content = local.bootstrap_nodes_evm_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "bootstrap_auto" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.bootstrap_nodes_autoid_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.auto-id-domain-node-config.domain-prefix}.${var.network_name}"
  content = local.bootstrap_nodes_autoid_ip_v4[count.index]
  type    = "A"
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "bootstrap_auto_ipv6" {
  lifecycle {
    ignore_changes = [name]
  }
  count   = length(local.bootstrap_nodes_autoid_ip_v4)
  zone_id = var.cloudflare_zone_id
  name    = "bootstrap-${count.index}.${var.auto-id-domain-node-config.domain-prefix}.${var.network_name}"
  content = local.bootstrap_nodes_autoid_ip_v6[count.index]
  type    = "AAAA"
  ttl     = 3600
  proxied = false
}
