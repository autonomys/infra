locals {
  staging_dir = "/home/${var.deployer.ssh_user}/subspace"
  peer_rules  = join(" ", [for r in var.peer_rules : "${r.protocol}:${r.port}:${r.from}"])
}

resource "null_resource" "bootstrap" {
  triggers = {
    ipv4             = var.host.ipv4
    hostname         = var.host.hostname
    public_tcp_ports = join(" ", var.public_tcp_ports)
    peer_rules       = local.peer_rules
    installer_hash   = filemd5("${var.deployer.path_to_scripts}/installer.sh")
    bootstrap_hash   = filemd5("${path.module}/bootstrap.sh")
  }

  connection {
    host           = var.host.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo mkdir -p ${local.staging_dir}/
      sudo chown -R ${var.deployer.ssh_user}:${var.deployer.ssh_user} ${local.staging_dir}/ && sudo chmod -R 750 ${local.staging_dir}/
      EOT
    ]
  }

  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/installer.sh"
    destination = "${local.staging_dir}/installer.sh"
  }

  provisioner "file" {
    source      = "${path.module}/bootstrap.sh"
    destination = "${local.staging_dir}/host-bootstrap.sh"
  }

  # There's no cloud-init to wait on here, so pause the background apt timers
  # and wait out any run in progress: they hold locks apt-get won't wait for.
  # The trap starts them again however this script ends.
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer
      trap 'sudo systemctl start apt-daily.timer apt-daily-upgrade.timer' EXIT
      trap 'exit 1' HUP INT TERM
      sudo systemd-run --quiet --property=After=apt-daily.service --property=After=apt-daily-upgrade.service --wait /bin/true
      sudo BOOTSTRAP_USER=${var.deployer.ssh_user} \
        BOOTSTRAP_HOSTNAME=${var.host.hostname} \
        INSTALLER=${local.staging_dir}/installer.sh \
        PUBLIC_TCP_PORTS='${join(" ", var.public_tcp_ports)}' \
        PEER_RULES='${local.peer_rules}' \
        bash ${local.staging_dir}/host-bootstrap.sh
      EOT
    ]
  }
}
