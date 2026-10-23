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
  #   - manual `pin_strategy` bump (escape hatch)
  triggers = merge(
    var.timekeeper-node-config.timekeeper-nodes[count.index],
    {
      pin_strategy  = "auto-favoured-v2"
      detector_hash = filemd5("${var.path_to_scripts}/detect-favoured-cpu.sh")
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

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      set -e
      trap 'sudo rm -f /home/${var.ssh_user}/subspace/config.toml' EXIT
      trap 'exit 1' HUP INT TERM

      # Apply CPU boost tuning inline. Each write is guarded so the block
      # no-ops cleanly on AMD/non-intel_pstate hosts (governor=performance
      # still applies via amd_pstate where present; HWP-specific writes
      # silently skip on hosts without /sys/devices/system/cpu/intel_pstate).
      # Note: these settings reset to defaults on host reboot — re-apply
      # terraform after any reboot to restore boost behavior.
      sudo bash -c '
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          [ -w "$f" ] && echo performance > "$f"
        done
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
          [ -w "$f" ] && echo performance > "$f"
        done
        [ -w /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost ] && echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost
      ' || true

      # Clean up the legacy systemd cpu-tuning.service if a previous version
      # of this module installed one. Idempotent — silent no-op on first run.
      if [ -f /etc/systemd/system/cpu-tuning.service ]; then
        sudo systemctl disable cpu-tuning.service 2>/dev/null || true
        sudo rm -f /etc/systemd/system/cpu-tuning.service
        sudo systemctl daemon-reload
      fi

      # set hostname
      sudo hostnamectl set-hostname ${var.network_name}-timekeeper-node-${var.timekeeper-node-config.timekeeper-nodes[count.index].index}

      # pull the node image and node-utils before the stop below, so a failed pull leaves the running timekeeper untouched
      sudo docker pull ghcr.io/autonomys/node:${var.timekeeper-node-config.timekeeper-nodes[count.index].docker-tag}
      sudo docker pull ghcr.io/autonomys/infra/node-utils:latest

      RENDER_COMPOSE="sudo docker run --rm --pull never -v /home/${var.ssh_user}/subspace:/data ghcr.io/autonomys/infra/node-utils:latest timekeeper \
          --network ${var.network_name} \
          --fqdn ${var.cloudflare_domain_fqdn} \
          --node-id ${var.timekeeper-node-config.timekeeper-nodes[count.index].index} \
          --docker-tag ${var.timekeeper-node-config.timekeeper-nodes[count.index].docker-tag} \
          --external-ip-v4 ${var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4} \
          --sync-mode ${var.timekeeper-node-config.timekeeper-nodes[count.index].sync-mode} \
          --is-reserved ${var.timekeeper-node-config.timekeeper-nodes[count.index].reserved-only}"

      # render once before the stop, so a bad config or node-utils flag fails the apply with the timekeeper still running
      $RENDER_COMPOSE --cpu-cores 0

      # stop any running service first so the stress-test below isn't fighting
      # the existing timekeeper for cycles
      if [ -f /home/${var.ssh_user}/subspace/docker-compose.yml ]; then
        sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down
      fi

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
      FAVOURED_CPU=$(/home/${var.ssh_user}/subspace/detect-favoured-cpu.sh || true)
      # Hardcoded fallback to cpu 0 only kicks in if detection somehow returns
      # nothing (no cpufreq sysfs, no /proc/cpuinfo "cpu MHz", etc.). Every
      # candidate-finding path in the script falls back to "first candidate"
      # before this, so this last-resort default rarely triggers.
      CPU_CORES=$${FAVOURED_CPU:-0}
      echo "Pinning timekeeper to cpu $CPU_CORES (auto-detected favoured cpu: '$FAVOURED_CPU')"

      # create docker compose
      $RENDER_COMPOSE --cpu-cores $CPU_CORES

      # start subspace node
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml up -d --remove-orphans

      # a node that is not running, or restarts within 30s, fails the apply before old images are pruned
      i=0
      until [ "$(sudo docker inspect --type container -f '{{.State.Status}}' node 2>/dev/null)" = running ]; do
        i=$((i+1))
        if [ "$i" -ge 300 ]; then echo "node container not running after 300s" >&2; exit 1; fi
        sleep 1
      done
      restarts=$(sudo docker inspect --type container -f '{{.RestartCount}}' node)
      sleep 30
      if [ "$(sudo docker inspect --type container -f '{{.State.Status}} {{.RestartCount}}' node)" != "running $restarts" ]; then
        echo "node container restarted or stopped within 30s of starting" >&2; exit 1
      fi

      # drop images left by previous deploys; the running one is protected
      sudo docker image prune -af
      EOT
    ]
  }
}
