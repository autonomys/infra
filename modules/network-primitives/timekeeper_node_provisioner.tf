resource "null_resource" "setup_timekeeper_nodes" {
  count = var.timekeeper-node-config == null ? 0 : length(var.timekeeper-node-config.timekeeper-nodes)

  connection {
    host           = var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # create subspace dir
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo apt update -y
      sudo mkdir -p /home/${var.ssh_user}/subspace/
      sudo chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/subspace/ && sudo chmod -R 750 /home/${var.ssh_user}/subspace/
      EOT
    ]
  }

  # copy install file
  provisioner "file" {
    source      = "${var.path_to_scripts}/installer.sh"
    destination = "/home/${var.ssh_user}/subspace/installer.sh"
  }

  # install docker and docker compose and LE script
  provisioner "remote-exec" {
    inline = [
      "sudo bash /home/${var.ssh_user}/subspace/installer.sh",
    ]
  }

}

resource "null_resource" "start_timekeeper_nodes" {
  count      = var.timekeeper-node-config == null ? 0 : length(var.timekeeper-node-config.timekeeper-nodes)
  depends_on = [null_resource.setup_timekeeper_nodes]

  # Trigger node deployment on:
  #   - any node config field change (image, ip, sync mode, etc.)
  #   - detector script change (filemd5)
  #   - cpu-tuning systemd unit change (filemd5)
  #   - manual `pin_strategy` bump (escape hatch)
  triggers = merge(
    var.timekeeper-node-config.timekeeper-nodes[count.index],
    {
      pin_strategy   = "auto-favoured-v2"
      detector_hash  = filemd5("${var.path_to_scripts}/detect-favoured-cpu.sh")
      cpu_tuning_hash = filemd5("${var.path_to_scripts}/cpu-tuning.service")
    }
  )

  connection {
    host           = var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  # copy config file
  provisioner "file" {
    source      = "./config.toml"
    destination = "/home/${var.ssh_user}/subspace/config.toml"
  }

  # copy favoured-cpu detector
  provisioner "file" {
    source      = "${var.path_to_scripts}/detect-favoured-cpu.sh"
    destination = "/home/${var.ssh_user}/subspace/detect-favoured-cpu.sh"
  }

  # copy cpu-tuning systemd unit
  provisioner "file" {
    source      = "${var.path_to_scripts}/cpu-tuning.service"
    destination = "/tmp/cpu-tuning.service"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # Install/refresh the cpu-tuning systemd one-shot. The unit writes
      # governor/EPP/HWP-boost sysfs values at every boot; each ExecStart is
      # `-` prefixed and guarded with `[ -w PATH ]` inside, so it no-ops
      # cleanly on AMD/non-intel_pstate hosts (governor=performance still
      # applies via amd_pstate or whatever's available; HWP-specific writes
      # silently skip). Idempotent — safe to redeploy on every start.
      sudo mv /tmp/cpu-tuning.service /etc/systemd/system/cpu-tuning.service
      sudo systemctl daemon-reload
      sudo systemctl enable cpu-tuning.service
      sudo systemctl restart cpu-tuning.service

      # stop any running service first so the stress-test below isn't fighting
      # the existing timekeeper for cycles
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down

      # Detect the favoured cpu via brief empirical stress on each candidate.
      # cpuinfo_max_freq alone can't differentiate cores that share the same
      # firmware-reported max but vary in actual silicon quality (typical on
      # 14900K — cores 8-11 all advertise 6000 MHz but only 1-2 actually
      # sustain it). The detector script stress-tests each candidate, samples
      # /proc/cpuinfo's live MSR-derived MHz, and returns the cpu that peaks
      # highest. On hardware without per-core differentiation (uniform Xeon,
      # ARM, or platforms missing /sys/devices/system/cpu/.../cpuinfo_max_freq)
      # the script returns empty and we fall back to the terraform-supplied
      # range — never fails the provisioner.
      chmod +x /home/${var.ssh_user}/subspace/detect-favoured-cpu.sh
      FAVOURED_CPU=$(/home/${var.ssh_user}/subspace/detect-favoured-cpu.sh)
      CPU_CORES=$${FAVOURED_CPU:-${var.timekeeper-node-config.timekeeper-nodes[count.index].cpu-cores}}
      echo "Pinning timekeeper to cpu $CPU_CORES (favoured detected: '$FAVOURED_CPU', terraform fallback: '${var.timekeeper-node-config.timekeeper-nodes[count.index].cpu-cores}')"

      # set hostname
      sudo hostnamectl set-hostname ${var.network_name}-timekeeper-node-${var.timekeeper-node-config.timekeeper-nodes[count.index].index}

      # create docker compose
      sudo docker run --rm --pull always -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest timekeeper \
          --network ${var.network_name} \
          --new-relic-api-key ${var.new_relic_api_key} \
          --fqdn ${var.cloudflare_domain_fqdn} \
          --node-id ${var.timekeeper-node-config.timekeeper-nodes[count.index].index} \
          --docker-tag ${var.timekeeper-node-config.timekeeper-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4} \
          --sync-mode ${var.timekeeper-node-config.timekeeper-nodes[count.index].sync-mode} \
          --cpu-cores $CPU_CORES \
          --is-reserved ${var.timekeeper-node-config.timekeeper-nodes[count.index].reserved-only}

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d

      # delete config file
      sudo rm -rf /home/${var.ssh_user}/subspace/config.toml
      EOT
    ]
  }
}
