module "auto_drive_staging" {
  source = "../../../modules/auto-drive-host"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  instance = {
    ipv4                = var.staging_host_ipv4
    hostname            = "auto-drive-staging-01"
    primary_domain      = "staging.auto-drive.autonomys.xyz"
    download_domain     = "download.staging.auto-drive.autonomys.xyz"
    auto_drive_repo_ref = var.auto_drive_repo_ref
  }

  letsencrypt_email    = var.letsencrypt_email
  cloudflare_api_token = var.cloudflare_api_token
}
