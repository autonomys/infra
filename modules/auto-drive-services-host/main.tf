locals {
  staging_dir     = module.host.staging_dir
  staged_dir      = "${local.staging_dir}/auto-drive-services"
  deploy_dir      = "/home/${var.deployer.ssh_user}/deploy/auto-drive-services"
  compose_project = "auto-drive-services"

  compose_file = templatefile("${path.module}/docker-compose.yml.tftpl", {
    loki_url                  = var.loki_url
    mesh_address              = var.mesh.address
    postgres_image            = var.images.postgres
    postgres_settings         = var.postgres.settings
    postgres_memory_limit_gib = var.postgres.memory_limit_gib
    postgres_shm_size_gib     = var.postgres.shm_size_gib
    rabbitmq_image            = var.images.rabbitmq
    rabbitmq_memory_limit_gib = var.rabbitmq.memory_limit_gib
    rabbitmq_conf_hash        = md5(local.rabbitmq_conf)
  })
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
    bootstrap_id       = module.host.bootstrap_id
    ipv4               = var.host.ipv4
    ssh_user           = var.deployer.ssh_user
    compose_hash       = md5(local.compose_file)
    rabbitmq_conf_hash = md5(local.rabbitmq_conf)
    postgres_env_hash  = nonsensitive(sha256(local.postgres_env))
    rabbitmq_env_hash  = nonsensitive(sha256(local.rabbitmq_env))
    databases          = join(" ", var.postgres.databases)
    deploy_hash        = filemd5("${path.module}/deploy.sh")
    port_guard_hash    = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
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

  provisioner "file" {
    content     = local.compose_file
    destination = "${local.staged_dir}/compose.yml"
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
        COMPOSE_PROJECT=${local.compose_project} \
        MESH_ADDRESS=${var.mesh.address} \
        POSTGRES_DATABASES='${join(" ", var.postgres.databases)}' \
        PORT_GUARD=${local.staging_dir}/compose-port-guard.py \
        bash ${local.staging_dir}/auto-drive-services-deploy.sh
      EOT
    ]
  }

  depends_on = [module.mesh]
}
