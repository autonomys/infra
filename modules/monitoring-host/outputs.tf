output "loki_domain" {
  value = var.instance.loki_domain
}

output "grafana_domain" {
  value = var.instance.grafana_domain
}

output "stack_dir" {
  value = local.stack_dir
}
