locals {
  home      = "/home/${var.deployer.ssh_user}"
  stack_dir = "${local.home}/monitoring"
  data_dir  = "/srv/monitoring"

  # the uid the grafana/grafana image runs as
  grafana_uid = 472

  loki_config = file("${path.module}/loki/config.yml")

  traefik_dynamic = templatefile("${path.module}/traefik/dynamic.yml.tftpl", {
    loki_domain    = var.instance.loki_domain
    grafana_domain = var.instance.grafana_domain
  })

  grafana_dir = "${path.module}/grafana"
  grafana_files = {
    for f in fileset(local.grafana_dir, "**") : f => filesha256("${local.grafana_dir}/${f}")
  }
  grafana_provisioning_sha = sha256(jsonencode({
    for f, sha in local.grafana_files : f => sha if startswith(f, "provisioning/")
  }))

  # Compose recreates a container when its labels change but not when a mounted
  # file does, so config hashes ride along as labels. Grafana reloads dashboards
  # by itself, so only its provisioning config is hashed.
  compose_env = <<-EOT
    LETSENCRYPT_EMAIL=${var.letsencrypt_email}
    DATA_DIR=${local.data_dir}
    LOKI_CONFIG_SHA=${sha256(local.loki_config)}
    GRAFANA_DOMAIN=${var.instance.grafana_domain}
    GRAFANA_CONFIG_SHA=${local.grafana_provisioning_sha}
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
    compose_hash       = filemd5("${path.module}/docker-compose.yml")
    loki_hash          = md5(local.loki_config)
    traefik_hash       = md5(local.traefik_dynamic)
    grafana_hash       = sha256(jsonencode(local.grafana_files))
    grafana_admin_hash = sha256(jsonencode(var.grafana_admin))
    env_hash           = md5(local.compose_env)
  })

  connection {
    host           = var.instance.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # Grafana's files go to a staging directory and are synced into place below.
  # Its directories are bind-mounted, so they are updated in place rather than
  # replaced.
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      set -e
      install -d -m 0755 ${local.stack_dir} ${local.stack_dir}/loki ${local.stack_dir}/traefik
      install -d -m 0755 ${local.stack_dir}/grafana/provisioning/datasources ${local.stack_dir}/grafana/provisioning/dashboards ${local.stack_dir}/grafana/dashboards
      install -d -m 0700 ${local.stack_dir}/secrets
      rm -rf ${local.stack_dir}/.upload
      install -d -m 0755 ${local.stack_dir}/.upload/grafana
      EOT
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
    source      = "${local.grafana_dir}/"
    destination = "${local.stack_dir}/.upload/grafana"
  }

  provisioner "file" {
    content     = var.grafana_admin.user
    destination = "${local.stack_dir}/secrets/grafana_admin_user"
  }

  provisioner "file" {
    content     = var.grafana_admin.password
    destination = "${local.stack_dir}/secrets/grafana_admin_password"
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

      cp -R .upload/grafana/. grafana/
      (cd grafana && find . -type f) | while read -r f; do
        [ -e ".upload/grafana/$f" ] || rm -f "grafana/$f"
      done
      rm -rf .upload
      sudo install -d -o ${local.grafana_uid} -g ${local.grafana_uid} -m 0750 ${local.data_dir}/grafana

      sudo docker compose config --quiet
      sudo docker compose pull --quiet
      sudo docker compose up -d --remove-orphans

      wait_ready() {
        for i in $(seq 1 60); do
          if curl -fsS -o /dev/null "$2"; then
            echo "==> $1 ready"
            return 0
          fi
          sleep 2
        done
        echo "$1 not ready after 120s" >&2
        sudo docker compose logs --tail 50 "$1" >&2
        return 1
      }
      wait_ready loki http://127.0.0.1:3100/ready
      wait_ready grafana http://127.0.0.1:3000/api/health

      # grafana cli prints Grafana's whole startup log along with the result
      if ! out="$(sudo docker compose exec -T grafana grafana cli admin reset-admin-password --password-from-stdin < secrets/grafana_admin_password 2>&1)"; then
        echo "$out" | grep -v 'level=info' >&2
        exit 1
      fi
      echo "==> Grafana admin password set"
      EOT
    ]
  }
}
