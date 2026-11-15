locals {
  staged_dir = "${var.host.staging_dir}/subspace-farmer"
  deploy_dir = "/home/${var.deployer.ssh_user}/deploy/subspace-farmer"

  # every .yml in compose/ is uploaded and installed, and only those count
  # towards the trigger; COMPOSE_FILE picks the ones in use
  compose_dir   = "${path.module}/compose"
  compose_files = ["docker-compose.yml"]

  public_tcp_ports = [var.ports.node, var.ports.node_dsn, var.ports.farmer]

  # Compose reads this from the deploy directory, so `docker compose` run there
  # by hand sees the same project, files and values as the deploy
  env = {
    COMPOSE_PROJECT_NAME = var.compose_project
    COMPOSE_FILE         = join(":", local.compose_files)
    NODE_IMAGE           = var.images.node
    FARMER_IMAGE         = var.images.farmer
    CHAIN                = var.chain
    SYNC                 = var.sync
    NODE_PORT            = var.ports.node
    NODE_DSN_PORT        = var.ports.node_dsn
    FARMER_PORT          = var.ports.farmer
    FARM_SIZE            = var.farm_size
    REWARD_ADDRESS       = var.reward_address
    PUBLIC_IPV4          = var.host.ipv4
    LOKI_URL             = var.loki_url
  }
  # single-quoted, so Compose takes each value literally; the variables' checks
  # keep quotes and line breaks out of them
  env_file = join("", [for k in keys(local.env) : "${k}='${local.env[k]}'\n"])
}

# Holds wait_for, so that the deploy, which depends on this, runs after
# whatever produced those IDs
resource "terraform_data" "wait_for" {
  input = var.wait_for
}

resource "null_resource" "deploy" {
  triggers = {
    bootstrap_id    = var.host.bootstrap_id
    ipv4            = var.host.ipv4
    ssh_user        = var.deployer.ssh_user
    compose_hash    = sha1(join("", [for f in sort(fileset(local.compose_dir, "*.yml")) : "${f}:${filesha1("${local.compose_dir}/${f}")}\n"]))
    env_hash        = md5(local.env_file)
    deploy_hash     = filemd5("${path.module}/deploy.sh")
    port_guard_hash = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
  }

  lifecycle {
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

  # deploy.sh empties it however it ends
  provisioner "remote-exec" {
    inline = ["install -d -m 0700 ${local.staged_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "${var.host.staging_dir}/subspace-farmer-deploy.sh"
  }

  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/compose-port-guard.py"
    destination = "${var.host.staging_dir}/compose-port-guard.py"
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
        PUBLIC_TCP_PORTS='${join(" ", local.public_tcp_ports)}' \
        PORT_GUARD=${var.host.staging_dir}/compose-port-guard.py \
        bash ${var.host.staging_dir}/subspace-farmer-deploy.sh
      EOT
    ]
  }

  depends_on = [terraform_data.wait_for]
}
