locals {
  staging_dir = "/home/${var.deployer.ssh_user}/subspace"

  config = templatefile("${path.module}/wg0.conf.tftpl", {
    address = var.mesh.address
    prefix  = split("/", var.mesh.subnet)[1]
    port    = var.mesh.port
    peers   = [for p in var.mesh.peers : p if p.public_key != ""]
  })
}

resource "null_resource" "mesh" {
  triggers = {
    ipv4        = var.host_ipv4
    config_hash = md5(local.config)
    mesh_hash   = filemd5("${path.module}/mesh.sh")
  }

  connection {
    host           = var.host_ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  provisioner "file" {
    content     = local.config
    destination = "${local.staging_dir}/wg0.conf"
  }

  provisioner "file" {
    source      = "${path.module}/mesh.sh"
    destination = "${local.staging_dir}/wireguard-mesh.sh"
  }

  # same apt timer pause as host-bootstrap, for the first run's package install
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer
      trap 'sudo systemctl start apt-daily.timer apt-daily-upgrade.timer' EXIT
      trap 'exit 1' HUP INT TERM
      sudo systemd-run --quiet --property=After=apt-daily.service --property=After=apt-daily-upgrade.service --wait /bin/true
      sudo MESH_CONFIG_SRC=${local.staging_dir}/wg0.conf \
        MESH_ADDRESS=${var.mesh.address} \
        bash ${local.staging_dir}/wireguard-mesh.sh
      EOT
    ]
  }
}
