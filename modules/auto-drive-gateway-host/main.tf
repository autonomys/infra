locals {
  staging_dir = module.host.staging_dir
  staged_dir  = "${local.staging_dir}/auto-drive-gateway"
  deploy_dir  = "/home/${var.deployer.ssh_user}/deploy/auto-drive-gateway"

  compose_file = templatefile("${path.module}/docker-compose.yml.tftpl", {
    node_image                 = var.images.node
    node_name                  = var.node.name
    node_rust_log              = var.node.rust_log
    network_id                 = var.network_id
    object_mapping_start_block = var.object_mapping_start_block
    loki_url                   = var.loki_url
  })
}

module "host" {
  source = "../host-bootstrap"

  deployer         = var.deployer
  host             = var.host
  public_tcp_ports = var.public_tcp_ports
  peer_rules       = var.peer_rules
}

module "mesh" {
  source = "../wireguard-mesh"
  count  = var.mesh == null ? 0 : 1

  deployer     = var.deployer
  bootstrap_id = module.host.bootstrap_id
  host_ipv4    = var.host.ipv4
  mesh         = var.mesh
}

resource "null_resource" "deploy" {
  # allow_node_restart is deliberately not a trigger: it only decides what a
  # deploy that runs anyway may do
  triggers = {
    bootstrap_id     = module.host.bootstrap_id
    ipv4             = var.host.ipv4
    ssh_user         = var.deployer.ssh_user
    compose_hash     = md5(local.compose_file)
    compose_project  = var.compose_project
    public_tcp_ports = join(" ", var.public_tcp_ports)
    mesh_address     = var.mesh == null ? "" : var.mesh.address
    deploy_hash      = filemd5("${path.module}/deploy.sh")
    port_guard_hash  = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
  }

  connection {
    host           = var.host.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # Only the deploy user can read it, since provisioners can't set a file's
  # mode; deploy.sh empties it however it ends.
  provisioner "remote-exec" {
    inline = ["install -d -m 0700 ${local.staged_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "${local.staging_dir}/auto-drive-gateway-deploy.sh"
  }

  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/compose-port-guard.py"
    destination = "${local.staging_dir}/compose-port-guard.py"
  }

  provisioner "file" {
    content     = local.compose_file
    destination = "${local.staged_dir}/compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo DEPLOY_USER=${var.deployer.ssh_user} \
        DEPLOY_DIR=${local.deploy_dir} \
        STAGED_DIR=${local.staged_dir} \
        COMPOSE_PROJECT=${var.compose_project} \
        PUBLIC_TCP_PORTS='${join(" ", var.public_tcp_ports)}' \
        PRIVATE_ADDRESSES='${var.mesh == null ? "" : var.mesh.address}' \
        ALLOW_NODE_RESTART=${var.allow_node_restart} \
        PORT_GUARD=${local.staging_dir}/compose-port-guard.py \
        bash ${local.staging_dir}/auto-drive-gateway-deploy.sh
      EOT
    ]
  }

  depends_on = [module.mesh]
}
