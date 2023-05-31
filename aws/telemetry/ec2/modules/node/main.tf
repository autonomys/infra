module "node" {
  source          = "../../base/"
  path_to_scripts = "../../base/scripts"
  network_name    = var.network_name

  telemetry-subspace-node-config = {
    network-name       = "${var.network_name}"
    domain-prefix      = "telemetry"
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  datadog_api_key      = var.datadog_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key

}
