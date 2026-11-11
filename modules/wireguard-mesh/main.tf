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
    bootstrap_id   = var.bootstrap_id
    ipv4           = var.host_ipv4
    config_hash    = md5(local.config)
    peer_endpoints = join(" ", sort(var.mesh.peers[*].endpoint))
    mesh_hash      = filemd5("${path.module}/mesh.sh")
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

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo MESH_CONFIG_SRC=${local.staging_dir}/wg0.conf \
        MESH_ADDRESS=${var.mesh.address} \
        MESH_PORT=${var.mesh.port} \
        MESH_PEER_ENDPOINTS='${join(" ", var.mesh.peers[*].endpoint)}' \
        bash ${local.staging_dir}/wireguard-mesh.sh
      EOT
    ]
  }
}
