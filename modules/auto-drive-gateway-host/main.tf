locals {
  staging_dir = module.host.staging_dir
  staged_dir  = "${local.staging_dir}/auto-drive-gateway"
  deploy_dir  = "/home/${var.deployer.ssh_user}/deploy/auto-drive-gateway"

  # every file in compose/ is uploaded and installed; COMPOSE_FILE picks the
  # ones in use
  compose_dir   = "${path.module}/compose"
  compose_files = concat(["docker-compose.yml"], var.cap_local_logs ? ["docker-compose.log-cap.yml"] : [])

  # Compose reads this from the deploy directory, so `docker compose` run there
  # by hand sees the same project, files and values as the deploy
  env = {
    COMPOSE_PROJECT_NAME       = var.compose_project
    COMPOSE_FILE               = join(":", local.compose_files)
    NODE_DOCKER_TAG            = var.images.node
    NETWORK_ID                 = var.network_id
    BLOCK_NUMBER_TO_START_FROM = var.create_object_mappings
    RUST_LOG_NODE              = var.node_rust_log
    LOKI_URL                   = var.loki_url
  }
  # single-quoted, so Compose takes each value literally instead of expanding a
  # $ in it; the precondition below keeps quotes out of the values
  env_file = join("", [for k in keys(local.env) : "${k}='${local.env[k]}'\n"])
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
  triggers = {
    bootstrap_id     = module.host.bootstrap_id
    ipv4             = var.host.ipv4
    ssh_user         = var.deployer.ssh_user
    compose_hash     = sha1(join("", [for f in sort(fileset(local.compose_dir, "*")) : "${f}:${filesha1("${local.compose_dir}/${f}")}\n"]))
    env_hash         = md5(local.env_file)
    public_tcp_ports = join(" ", var.public_tcp_ports)
    mesh_address     = var.mesh == null ? "" : var.mesh.address
    deploy_hash      = filemd5("${path.module}/deploy.sh")
    port_guard_hash  = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
  }

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(local.env) : !strcontains(v, "'")])
      error_message = "A value for the gateway's .env contains a single quote, which its quoting can't hold."
    }
    precondition {
      condition     = alltrue([for f in local.compose_files : fileexists("${local.compose_dir}/${f}")])
      error_message = "COMPOSE_FILE names a file that is not in the module's compose/ directory."
    }
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

  # the trailing slash uploads the directory's contents
  provisioner "file" {
    source      = "${local.compose_dir}/"
    destination = local.staged_dir
  }

  provisioner "file" {
    content     = local.env_file
    destination = "${local.staged_dir}/.env"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo DEPLOY_USER=${var.deployer.ssh_user} \
        DEPLOY_DIR=${local.deploy_dir} \
        STAGED_DIR=${local.staged_dir} \
        PUBLIC_TCP_PORTS='${join(" ", var.public_tcp_ports)}' \
        PRIVATE_ADDRESSES='${var.mesh == null ? "" : var.mesh.address}' \
        PORT_GUARD=${local.staging_dir}/compose-port-guard.py \
        bash ${local.staging_dir}/auto-drive-gateway-deploy.sh
      EOT
    ]
  }

  depends_on = [module.mesh]
}
