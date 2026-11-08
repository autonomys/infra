locals {
  home      = "/home/${var.deployer.ssh_user}"
  stack_dir = "${local.home}/monitoring"
  data_dir  = "/srv/monitoring"

  loki_config = file("${path.module}/loki/config.yml")

  traefik_dynamic = templatefile("${path.module}/traefik/dynamic.yml.tftpl", {
    loki_domain = var.instance.loki_domain
  })

  # Compose recreates a container when its labels change but not when a mounted
  # file does, so the Loki config's hash rides along as a label
  compose_env = <<-EOT
    LETSENCRYPT_EMAIL=${var.letsencrypt_email}
    DATA_DIR=${local.data_dir}
    LOKI_CONFIG_SHA=${sha256(local.loki_config)}
  EOT
}

resource "null_resource" "setup_monitoring_host" {
  triggers = {
    ipv4           = var.instance.ipv4
    installer_hash = filemd5("${var.deployer.path_to_scripts}/installer.sh")
    bootstrap_hash = filemd5("${var.deployer.path_to_scripts}/monitoring-host-bootstrap.sh")
  }

  connection {
    host           = var.instance.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # There's no cloud-init to wait on, so pause the background apt timers and wait
  # out any run in progress: they hold locks apt-get won't wait for. The timers
  # are started again after the bootstrap.
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

  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/installer.sh"
    destination = "${local.home}/subspace/installer.sh"
  }

  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/monitoring-host-bootstrap.sh"
    destination = "${local.home}/subspace/monitoring-host-bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo bash ${local.home}/subspace/installer.sh
      sudo MONITORING_USER=${var.deployer.ssh_user} \
        MONITORING_DATA_DIR=${local.data_dir} \
        bash ${local.home}/subspace/monitoring-host-bootstrap.sh
      status=$?
      sudo systemctl start apt-daily.timer apt-daily-upgrade.timer
      exit $status
      EOT
    ]
  }
}

resource "null_resource" "deploy_monitoring_stack" {
  depends_on = [null_resource.setup_monitoring_host]

  triggers = merge(var.instance, {
    compose_hash = filemd5("${path.module}/docker-compose.yml")
    loki_hash    = md5(local.loki_config)
    traefik_hash = md5(local.traefik_dynamic)
    env_hash     = md5(local.compose_env)
  })

  connection {
    host           = var.instance.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  provisioner "remote-exec" {
    inline = [
      "install -d -m 0755 ${local.stack_dir} ${local.stack_dir}/loki ${local.stack_dir}/traefik",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/docker-compose.yml"
    destination = "${local.stack_dir}/docker-compose.yml"
  }

  provisioner "file" {
    content     = local.loki_config
    destination = "${local.stack_dir}/loki/config.yml"
  }

  provisioner "file" {
    content     = local.traefik_dynamic
    destination = "${local.stack_dir}/traefik/dynamic.yml"
  }

  provisioner "file" {
    content     = local.compose_env
    destination = "${local.stack_dir}/.env"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      set -e
      cd ${local.stack_dir}

      sudo hostnamectl set-hostname ${var.instance.hostname}

      sudo docker compose config --quiet
      sudo docker compose pull --quiet
      sudo docker compose up -d --remove-orphans

      for i in $(seq 1 60); do
        if curl -fsS -o /dev/null http://127.0.0.1:3100/ready; then
          echo "==> Loki ready"
          exit 0
        fi
        sleep 2
      done
      echo "Loki not ready after 120s" >&2
      sudo docker compose logs --tail 50 loki >&2
      exit 1
      EOT
    ]
  }
}
