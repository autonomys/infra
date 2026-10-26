locals {
  home       = "/home/${var.deployer.ssh_user}"
  deploy_dir = "/home/${var.deployer.ssh_user}/deploy/auto-drive"
  # the auto-drive deploy playbook runs this file for hosts whose inventory group
  # sets compose_file to it; production groups keep docker-compose.prod.yml
  compose_file = "${local.deploy_dir}/docker-compose.staging.yml"
  nginx_site   = var.instance.hostname

  nginx_conf = templatefile("${path.module}/nginx/auto-drive-host.conf.tftpl", {
    primary_domain  = var.instance.primary_domain
    download_domain = var.instance.download_domain
  })

  # shipped as a file rather than an env var like the rest, to keep the token out
  # of the process table
  cloudflare_credentials = "dns_cloudflare_api_token = ${var.cloudflare_api_token}\n"
}

resource "null_resource" "setup_auto_drive_host" {
  triggers = {
    ipv4              = var.instance.ipv4
    installer_hash    = filemd5("${var.deployer.path_to_scripts}/installer.sh")
    bootstrap_hash    = filemd5("${var.deployer.path_to_scripts}/auto-drive-host-bootstrap.sh")
    primary_domain    = var.instance.primary_domain
    download_domain   = var.instance.download_domain
    repo_ref          = var.instance.auto_drive_repo_ref
    letsencrypt_email = var.letsencrypt_email
  }

  connection {
    host           = var.instance.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # init host. There's no cloud-init to wait on here, so pause the background apt
  # timers and wait out any run in progress: they hold locks apt-get won't wait
  # for. The timers are started again after the bootstrap.
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer
      sudo systemd-run --quiet --property=After=apt-daily.service --property=After=apt-daily-upgrade.service --wait /bin/true
      sudo apt update -y
      sudo mkdir -p ${local.home}/subspace/
      sudo chown -R ${var.deployer.ssh_user}:${var.deployer.ssh_user} ${local.home}/subspace/ && sudo chmod -R 750 ${local.home}/subspace/
      EOT
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/installer.sh"
    destination = "${local.home}/subspace/installer.sh"
  }

  # copy host bootstrap file
  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/auto-drive-host-bootstrap.sh"
    destination = "${local.home}/subspace/auto-drive-host-bootstrap.sh"
  }

  # copy certbot cloudflare credentials
  provisioner "file" {
    content     = local.cloudflare_credentials
    destination = "${local.home}/subspace/cloudflare.ini"
  }

  # install docker, then bootstrap the host
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo bash ${local.home}/subspace/installer.sh
      sudo AUTO_DRIVE_USER=${var.deployer.ssh_user} \
        AUTO_DRIVE_DEPLOY_DIR=${local.deploy_dir} \
        AUTO_DRIVE_REPO_REF=${var.instance.auto_drive_repo_ref} \
        PRIMARY_DOMAIN=${var.instance.primary_domain} \
        DOWNLOAD_DOMAIN=${var.instance.download_domain} \
        LETSENCRYPT_EMAIL=${var.letsencrypt_email} \
        CLOUDFLARE_CREDENTIALS_SRC=${local.home}/subspace/cloudflare.ini \
        bash ${local.home}/subspace/auto-drive-host-bootstrap.sh
      status=$?
      sudo systemctl start apt-daily.timer apt-daily-upgrade.timer
      exit $status
      EOT
    ]
  }
}

resource "null_resource" "configure_auto_drive_host" {
  depends_on = [null_resource.setup_auto_drive_host]

  triggers = merge(var.instance, {
    compose_hash = filemd5("${path.module}/docker-compose.yml")
    nginx_hash   = md5(local.nginx_conf)
  })

  connection {
    host           = var.instance.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  provisioner "file" {
    source      = "${path.module}/docker-compose.yml"
    destination = local.compose_file
  }

  provisioner "file" {
    content     = local.nginx_conf
    destination = "${local.home}/subspace/${local.nginx_site}.conf"
  }

  # containers are not started here: .env only exists once the deploy workflow
  # has fetched it from Infisical
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      set -e

      sudo hostnamectl set-hostname ${var.instance.hostname}

      sudo install -o root -g root -m 0644 \
        ${local.home}/subspace/${local.nginx_site}.conf \
        /etc/nginx/sites-available/${local.nginx_site}
      sudo ln -sfn /etc/nginx/sites-available/${local.nginx_site} \
        /etc/nginx/sites-enabled/${local.nginx_site}
      sudo rm -f /etc/nginx/sites-enabled/default

      sudo nginx -t
      sudo systemctl reload nginx
      EOT
    ]
  }
}
