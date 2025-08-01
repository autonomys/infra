# TODO use this to pass fqdn to config generation
data "cloudflare_zone" "cloudflare_zone" {
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "consensus_bootstrap_ipv4" {
  lifecycle {
    ignore_changes = [name]
  }
  depends_on = [aws_instance.consensus_bootstrap_nodes]
  count      = length(aws_instance.consensus_bootstrap_nodes)
  zone_id    = var.cloudflare_zone_id
  name       = "bootstrap-${count.index}.${var.network_name}"
  content    = aws_instance.consensus_bootstrap_nodes[count.index].public_ip
  type       = "A"
  ttl        = 3600
  proxied    = false
}

resource "cloudflare_dns_record" "consensus_bootstrap_ipv6" {
  lifecycle {
    ignore_changes = [name]
  }
  depends_on = [aws_instance.consensus_bootstrap_nodes]
  count      = length(aws_instance.consensus_bootstrap_nodes)
  zone_id    = var.cloudflare_zone_id
  name       = "bootstrap-${count.index}.${var.network_name}"
  content    = aws_instance.consensus_bootstrap_nodes[count.index].ipv6_addresses[0]
  type       = "AAAA"
  ttl        = 3600
  proxied    = false
}

# TODO: load balancing
resource "cloudflare_dns_record" "consensus_rpc" {
  lifecycle {
    ignore_changes = [name]
  }
  depends_on = [aws_instance.consensus_rpc_nodes]
  count      = var.consensus-rpc-node-config == null ? 0 : var.consensus-rpc-node-config.enable-reverse-proxy ? length(aws_instance.consensus_rpc_nodes) : 0
  zone_id    = var.cloudflare_zone_id
  name       = "${var.consensus-rpc-node-config.dns-prefix}-${count.index}.${var.network_name}"
  content    = aws_instance.consensus_rpc_nodes[count.index].public_ip
  type       = "A"
  ttl        = 1
  proxied    = true
}

resource "cloudflare_dns_record" "domain_bootstrap_ipv4" {
  lifecycle {
    ignore_changes = [name]
  }
  depends_on = [aws_instance.domain_bootstrap_nodes]
  count      = length(aws_instance.domain_bootstrap_nodes)
  zone_id    = var.cloudflare_zone_id
  name       = "bootstrap-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].index}.${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-name}.${var.network_name}"
  content    = aws_instance.domain_bootstrap_nodes[count.index].public_ip
  type       = "A"
  ttl        = 3600
  proxied    = false
}

resource "cloudflare_dns_record" "bootstrap_evm_ipv6" {
  lifecycle {
    ignore_changes = [name]
  }
  depends_on = [aws_instance.domain_bootstrap_nodes]
  count      = length(aws_instance.domain_bootstrap_nodes)
  zone_id    = var.cloudflare_zone_id
  name       = "bootstrap-${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].index}.${var.domain-bootstrap-node-config.bootstrap-nodes[count.index].domain-name}.${var.network_name}"
  content    = aws_instance.domain_bootstrap_nodes[count.index].ipv6_addresses[0]
  type       = "AAAA"
  ttl        = 3600
  proxied    = false
}

# TODO: load balancing
resource "cloudflare_dns_record" "domain_rpc" {
  lifecycle {
    ignore_changes = [name]
  }
  depends_on = [aws_instance.domain_rpc_nodes]
  count      = var.domain-rpc-node-config == null ? 0 : var.domain-rpc-node-config.enable-reverse-proxy ? length(aws_instance.domain_rpc_nodes) : 0
  zone_id    = var.cloudflare_zone_id
  name       = "${var.domain-rpc-node-config.rpc-nodes[count.index].domain-name}-${var.domain-rpc-node-config.rpc-nodes[count.index].index}.${var.network_name}"
  content    = aws_instance.domain_rpc_nodes[count.index].public_ip
  type       = "A"
  ttl        = 1
  proxied    = true
}
