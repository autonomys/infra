locals {
  staging_dir = module.host.staging_dir
  staged_dir  = "${local.staging_dir}/auto-drive-services"
  deploy_dir  = "/home/${var.deployer.ssh_user}/deploy/auto-drive-services"

  # every .yml in compose/ is uploaded and installed, and only those count
  # towards the trigger; COMPOSE_FILE picks the ones in use
  compose_dir   = "${path.module}/compose"
  compose_files = ["docker-compose.yml"]

  # Compose reads this from the deploy directory, so `docker compose` run there
  # by hand sees the same project, files and values as the deploy. Each Postgres
  # setting becomes POSTGRES_<NAME>, which the compose file passes as -c.
  env = merge({
    COMPOSE_PROJECT_NAME  = "auto-drive-services"
    COMPOSE_FILE          = join(":", local.compose_files)
    POSTGRES_IMAGE        = var.images.postgres
    RABBITMQ_IMAGE        = var.images.rabbitmq
    MESH_ADDRESS          = var.mesh.address
    LOKI_URL              = var.loki_url
    POSTGRES_MEMORY_LIMIT = "${var.postgres.memory_limit_gib}g"
    POSTGRES_SHM_SIZE     = "${var.postgres.shm_size_gib}g"
    RABBITMQ_MEMORY_LIMIT = "${var.rabbitmq.memory_limit_gib}g"
    RABBITMQ_CONF_HASH    = md5(local.rabbitmq_conf)
  }, { for name, value in var.postgres.settings : "POSTGRES_${upper(name)}" => value })
  # single-quoted, so Compose takes each value literally instead of expanding a
  # $ in it; the precondition below keeps quotes out of the values
  env_file = join("", [for k in keys(local.env) : "${k}='${local.env[k]}'\n"])

  rabbitmq_conf = "total_memory_available_override_value = ${var.rabbitmq.memory_limit_gib}GiB\n"

  postgres_env = "POSTGRES_PASSWORD=${var.postgres_password}\n"
  rabbitmq_env = "RABBITMQ_DEFAULT_USER=${var.rabbitmq_username}\nRABBITMQ_DEFAULT_PASS=${var.rabbitmq_password}\n"
}

module "host" {
  source = "../host-bootstrap"

  deployer   = var.deployer
  host       = var.host
  peer_rules = var.peer_rules
}

module "mesh" {
  source = "../wireguard-mesh"

  deployer     = var.deployer
  bootstrap_id = module.host.bootstrap_id
  host_ipv4    = var.host.ipv4
  mesh         = var.mesh
}

resource "null_resource" "deploy" {
  # hashes only: the credentials themselves never reach the state
  triggers = {
    bootstrap_id      = module.host.bootstrap_id
    ipv4              = var.host.ipv4
    ssh_user          = var.deployer.ssh_user
    compose_hash      = sha1(join("", [for f in sort(fileset(local.compose_dir, "*.yml")) : "${f}:${filesha1("${local.compose_dir}/${f}")}\n"]))
    env_hash          = md5(local.env_file)
    postgres_env_hash = nonsensitive(sha256(local.postgres_env))
    rabbitmq_env_hash = nonsensitive(sha256(local.rabbitmq_env))
    databases         = join(" ", var.postgres.databases)
    deploy_hash       = filemd5("${path.module}/deploy.sh")
    port_guard_hash   = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
  }

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(local.env) : !strcontains(v, "'")])
      error_message = "A value for the services host's .env contains a single quote, which its quoting can't hold."
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

  # A directory only the deploy user can read, since provisioners can't set a
  # file's mode; deploy.sh empties it however it ends. The credentials go last,
  # so an upload that fails early leaves none behind.
  provisioner "remote-exec" {
    inline = ["install -d -m 0700 ${local.staged_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "${local.staging_dir}/auto-drive-services-deploy.sh"
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

  provisioner "file" {
    content     = local.rabbitmq_conf
    destination = "${local.staged_dir}/rabbitmq.conf"
  }

  provisioner "file" {
    content     = local.postgres_env
    destination = "${local.staged_dir}/postgres.env"
  }

  provisioner "file" {
    content     = local.rabbitmq_env
    destination = "${local.staged_dir}/rabbitmq.env"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo DEPLOY_USER=${var.deployer.ssh_user} \
        DEPLOY_DIR=${local.deploy_dir} \
        STAGED_DIR=${local.staged_dir} \
        MESH_ADDRESS=${var.mesh.address} \
        POSTGRES_DATABASES='${join(" ", var.postgres.databases)}' \
        PORT_GUARD=${local.staging_dir}/compose-port-guard.py \
        bash ${local.staging_dir}/auto-drive-services-deploy.sh
      EOT
    ]
  }

  depends_on = [module.mesh]
}
