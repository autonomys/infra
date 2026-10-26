output "host_ipv4" {
  value = var.instance.ipv4
}

output "primary_domain" {
  value = var.instance.primary_domain
}

output "download_domain" {
  value = var.instance.download_domain
}

output "deploy_dir" {
  value = local.deploy_dir
}

output "compose_file" {
  value = local.compose_file
}
