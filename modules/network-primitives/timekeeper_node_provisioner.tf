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

resource "null_resource" "tune_timekeeper_nodes" {
  count      = var.timekeeper-node-config == null ? 0 : length(var.timekeeper-node-config.timekeeper-nodes)
  depends_on = [null_resource.setup_timekeeper_nodes]

  # re-run when the unit changes
  triggers = {
    unit_hash = filemd5("${var.path_to_scripts}/cpu-tuning.service")
  }

  connection {
    host           = var.timekeeper-node-config.timekeeper-nodes[count.index].ipv4
    user           = var.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.ssh_agent_identity
    timeout        = "300s"
  }

  provisioner "file" {
    source      = "${var.path_to_scripts}/cpu-tuning.service"
    destination = "/tmp/cpu-tuning.service"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo mv /tmp/cpu-tuning.service /etc/systemd/system/cpu-tuning.service
      sudo systemctl daemon-reload
      sudo systemctl enable cpu-tuning.service
      sudo systemctl restart cpu-tuning.service
      EOT
    ]
  }
}

resource "null_resource" "start_timekeeper_nodes" {
  count      = var.timekeeper-node-config == null ? 0 : length(var.timekeeper-node-config.timekeeper-nodes)
  depends_on = [null_resource.setup_timekeeper_nodes, null_resource.tune_timekeeper_nodes]

  # Trigger node deployment on node object change. The synthetic `pin_strategy`
  # key forces a one-time recreation when we switch the cpu-cores selection
  # logic — bump the version when the strategy changes.
  triggers = merge(
    var.timekeeper-node-config.timekeeper-nodes[count.index],
    { pin_strategy = "auto-favoured-v1" }
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

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # Detect the favoured cpu — the one with the highest cpuinfo_max_freq.
      # Intel TVB-eligible cores expose a higher ceiling than the rest of the
      # P-cores; AMD CPPC preferred cores show similarly. On uniform-core
      # silicon (server Xeon, Graviton) all values are equal and we pick the
      # lowest-numbered core deterministically. Falls back to the terraform-
      # supplied range if /sys is unreadable for any reason.
      FAVOURED_CPU=$(
        for f in /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq; do
          [ -r "$f" ] && echo "$(cat "$f") $(echo "$f" | sed -E 's:.*/cpu([0-9]+)/.*:\1:')"
        done 2>/dev/null | sort -n -r | head -1 | awk '{print $2}'
      )
      CPU_CORES=$${FAVOURED_CPU:-${var.timekeeper-node-config.timekeeper-nodes[count.index].cpu-cores}}
      echo "Pinning timekeeper to cpu $CPU_CORES (favoured detected: '$FAVOURED_CPU', terraform fallback: '${var.timekeeper-node-config.timekeeper-nodes[count.index].cpu-cores}')"

      # stop any running service
      sudo docker compose -f /home/${var.ssh_user}/subspace/docker-compose.yml down

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
