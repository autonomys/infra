locals {
  home      = "/home/${var.deployer.ssh_user}"
  stack_dir = "${local.home}/monitoring"
  data_dir  = "/srv/monitoring"

  # the uids the grafana/grafana and prom/alertmanager images run as
  grafana_uid      = 472
  alertmanager_uid = 65534

  loki_config = file("${path.module}/loki/config.yml")

  traefik_dynamic = templatefile("${path.module}/traefik/dynamic.yml.tftpl", {
    loki_domain     = var.instance.loki_domain
    grafana_domain  = var.instance.grafana_domain
    vmetrics_domain = var.instance.vmetrics_domain
  })

  vmauth_config = templatefile("${path.module}/vmauth/auth.yml.tftpl", {
    writer = var.vmetrics_writer
    fleet  = var.vmetrics_fleet
  })

  # Directories copied to the box as they are, then synced into place
  config_dirs = ["grafana", "vmagent", "vmalert", "alertmanager", "watchdog-relay", "blackbox"]
  config_files = {
    for d in local.config_dirs : d => {
      for f in fileset("${path.module}/${d}", "**") : f => filesha256("${path.module}/${d}/${f}")
    }
  }
  config_sha = { for d, files in local.config_files : d => sha256(jsonencode(files)) }

  grafana_provisioning_sha = sha256(jsonencode({
    for f, sha in local.config_files["grafana"] : f => sha if startswith(f, "provisioning/")
  }))

  # Third-party dashboards, fetched from grafana.com at pinned revisions rather
  # than copied into this public repo
  grafana_com_dashboards = [
    { file = "node-exporter-full.json", id = 1860, revision = 46, sha256 = "e58ddc5dc535d4c901f94da9648bc3e3d5ae7b6f78e98e185bce8b289961cea3" },
    { file = "victoriametrics.json", id = 10229, revision = 61, sha256 = "93f445b4ba1305eb8b84f9def54a4f050addf5af4f839d59e644b3fac9a7c31a" },
  ]

  # Compose recreates a container when its labels change but not when a mounted
  # file does, so config hashes ride along as labels. Grafana reloads dashboards
  # by itself, so only its provisioning config is hashed.
  compose_env = <<-EOT
    LETSENCRYPT_EMAIL=${var.letsencrypt_email}
    DATA_DIR=${local.data_dir}
    MONITORING_HOSTNAME=${var.instance.hostname}
    LOKI_CONFIG_SHA=${sha256(local.loki_config)}
    GRAFANA_DOMAIN=${var.instance.grafana_domain}
    GRAFANA_CONFIG_SHA=${local.grafana_provisioning_sha}
    VMAGENT_CONFIG_SHA=${local.config_sha["vmagent"]}
    VMALERT_RULES_SHA=${local.config_sha["vmalert"]}
    ALERTMANAGER_CONFIG_SHA=${local.config_sha["alertmanager"]}
    WATCHDOG_RELAY_SHA=${local.config_sha["watchdog-relay"]}
    BLACKBOX_CONFIG_SHA=${local.config_sha["blackbox"]}
  EOT
}

resource "null_resource" "setup_monitoring_host" {
  # A reinstalled box has new host keys, so rebuilding it at the same address sets
  # it up again, and the stack deploy follows
  triggers = {
    ipv4           = var.instance.ipv4
    host_key       = var.host_key
    installer_hash = filemd5("${var.deployer.path_to_scripts}/installer.sh")
    bootstrap_hash = filemd5("${var.deployer.path_to_scripts}/monitoring-host-bootstrap.sh")
  }

  connection {
    host           = var.instance.ipv4
    host_key       = var.host_key
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
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

  # There's no cloud-init to wait on, so pause the background apt timers and wait
  # out any run in progress: they hold locks apt-get won't wait for. The trap
  # starts them again however this script ends.
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      trap 'sudo systemctl start apt-daily.timer apt-daily-upgrade.timer' EXIT
      trap 'exit 1' HUP INT TERM
      set -e
      sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer
      sudo systemd-run --quiet --property=After=apt-daily.service --property=After=apt-daily-upgrade.service --wait /bin/true
      sudo apt update -y
      sudo bash -e ${local.home}/subspace/installer.sh
      sudo MONITORING_USER=${var.deployer.ssh_user} \
        MONITORING_DATA_DIR=${local.data_dir} \
        bash ${local.home}/subspace/monitoring-host-bootstrap.sh
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
    grafana_hash       = local.config_sha["grafana"]
    vmagent_hash       = local.config_sha["vmagent"]
    vmalert_hash       = local.config_sha["vmalert"]
    alertmanager_hash  = local.config_sha["alertmanager"]
    relay_hash         = local.config_sha["watchdog-relay"]
    blackbox_hash      = local.config_sha["blackbox"]
    dashboards_hash    = sha256(jsonencode(local.grafana_com_dashboards))
    grafana_admin_hash = sha256(jsonencode(var.grafana_admin))
    alerting_hash      = sha256(jsonencode(var.alerting))
    vmauth_hash        = sha256(local.vmauth_config)
    env_hash           = md5(local.compose_env)
    setup_id           = null_resource.setup_monitoring_host.id
  })

  connection {
    host           = var.instance.ipv4
    host_key       = var.host_key
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # The config directories go to a staging directory and are synced into place
  # below. They are bind-mounted, so they are updated in place rather than
  # replaced.
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      set -e
      install -d -m 0755 ${local.stack_dir} ${local.stack_dir}/loki ${local.stack_dir}/traefik
      install -d -m 0700 ${local.stack_dir}/secrets
      rm -rf ${local.stack_dir}/.upload
      %{for d in local.config_dirs~}
      install -d -m 0755 ${local.stack_dir}/${d} ${local.stack_dir}/.upload/${d}
      %{endfor~}
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
    source      = "${path.module}/grafana/"
    destination = "${local.stack_dir}/.upload/grafana"
  }

  provisioner "file" {
    source      = "${path.module}/vmagent/"
    destination = "${local.stack_dir}/.upload/vmagent"
  }

  provisioner "file" {
    source      = "${path.module}/vmalert/"
    destination = "${local.stack_dir}/.upload/vmalert"
  }

  provisioner "file" {
    source      = "${path.module}/alertmanager/"
    destination = "${local.stack_dir}/.upload/alertmanager"
  }

  provisioner "file" {
    source      = "${path.module}/watchdog-relay/"
    destination = "${local.stack_dir}/.upload/watchdog-relay"
  }

  provisioner "file" {
    source      = "${path.module}/blackbox/"
    destination = "${local.stack_dir}/.upload/blackbox"
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
    content     = var.alerting.slack_webhook_url
    destination = "${local.stack_dir}/secrets/alertmanager_slack_webhook_url"
  }

  provisioner "file" {
    content     = var.alerting.watchdog_push_url
    destination = "${local.stack_dir}/secrets/watchdog_push_url"
  }

  provisioner "file" {
    content     = local.vmauth_config
    destination = "${local.stack_dir}/secrets/vmauth_auth.yml"
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

      install -d -m 0755 .upload/grafana/dashboards/metrics
      fetch_dashboard() {
        curl -fsSL --retry 3 -o ".upload/grafana/dashboards/metrics/$1" "https://grafana.com/api/dashboards/$2/revisions/$3/download"
        echo "$4  .upload/grafana/dashboards/metrics/$1" | sha256sum --check --quiet
      }
      %{for d in local.grafana_com_dashboards~}
      fetch_dashboard ${d.file} ${d.id} ${d.revision} ${d.sha256}
      %{endfor~}

      for d in ${join(" ", local.config_dirs)}; do
        cp -R ".upload/$d/." "$d/"
        (cd "$d" && find . -type f) | while read -r f; do
          [ -e ".upload/$d/$f" ] || rm -f "$d/$f"
        done
      done
      rm -rf .upload

      sudo install -d -o ${local.grafana_uid} -g ${local.grafana_uid} -m 0750 ${local.data_dir}/grafana
      sudo install -d -o ${local.alertmanager_uid} -g ${local.alertmanager_uid} -m 0750 ${local.data_dir}/alertmanager
      sudo install -d -m 0750 ${local.data_dir}/victoriametrics ${local.data_dir}/vmagent

      # Read by node_exporter's textfile collector for the DiskMissing rule
      sudo install -d -m 0755 /var/lib/node_exporter/textfile
      printf 'node_disks_expected %d\n' ${var.instance.disks} | sudo tee /var/lib/node_exporter/textfile/disks.prom.tmp > /dev/null
      sudo mv /var/lib/node_exporter/textfile/disks.prom.tmp /var/lib/node_exporter/textfile/disks.prom

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
      wait_ready victoriametrics http://127.0.0.1:8428/health
      wait_ready vmalert http://127.0.0.1:8880/health
      wait_ready alertmanager http://127.0.0.1:9093/-/ready
      wait_ready vmauth http://127.0.0.1:8427/health
      wait_ready blackbox-exporter http://127.0.0.1:9115/-/healthy

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
