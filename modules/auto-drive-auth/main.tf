locals {
  staged_dir = "${var.host.staging_dir}/auto-drive-auth"
  deploy_dir = "/home/${var.deployer.ssh_user}/deploy/auto-drive-auth"

  # every .yml in compose/ is uploaded and installed, and only those count
  # towards the trigger; COMPOSE_FILE picks the ones in use
  compose_dir   = "${path.module}/compose"
  compose_files = ["docker-compose.yml"]

  # Compose reads this from the deploy directory, so `docker compose` run there
  # by hand sees the same project, files and values as the deploy
  env = {
    COMPOSE_PROJECT_NAME                   = var.compose_project
    COMPOSE_FILE                           = join(":", local.compose_files)
    AUTH_IMAGE                             = var.image
    PUBLISH_ADDRESS                        = var.publish_address
    AUTH_HOST_PORT                         = var.port
    DATABASE_ID                            = var.database_id
    LOKI_URL                               = var.loki_url
    JWT_SECRET_ALGORITHM                   = var.settings.jwt_algorithm
    CORS_ALLOWED_ORIGINS                   = var.settings.cors_allowed_origins
    WEB3_AUTH_ALLOWED_ORIGINS              = var.settings.web3_allowed_origins
    LOG_LEVEL                              = var.settings.log_level
    REVOKE_TOKEN_EMITTED_BEFORE_IN_SECONDS = var.settings.revoke_tokens_issued_before
  }
  # single-quoted, so Compose takes each value literally instead of expanding a
  # $ in it; the variables' checks keep quotes and line breaks out of them
  env_file = join("", [for k in keys(local.env) : "${k}='${local.env[k]}'\n"])

  # auth decodes JWT_SECRET from base64 before using it as the key
  secrets = {
    DATABASE_URL = var.database_url
    JWT_SECRET   = base64encode(var.jwt_private_key)
    API_SECRET   = var.api_secret
  }
  auth_env_file = join("", [for k in keys(local.secrets) : "${k}='${local.secrets[k]}'\n"])
}

# Holds wait_for, so that the deploy, which depends on this, runs after
# whatever produced those IDs
resource "terraform_data" "wait_for" {
  input = var.wait_for
}

resource "null_resource" "deploy" {
  # hashes only: the credentials themselves never reach the state
  triggers = {
    bootstrap_id      = var.host.bootstrap_id
    ipv4              = var.host.ipv4
    ssh_user          = var.deployer.ssh_user
    compose_hash      = sha1(join("", [for f in sort(fileset(local.compose_dir, "*.yml")) : "${f}:${filesha1("${local.compose_dir}/${f}")}\n"]))
    env_hash          = md5(local.env_file)
    auth_env_hash     = nonsensitive(sha256(local.auth_env_file))
    jwt_public_key    = md5(var.jwt_public_key)
    private_addresses = join(" ", var.private_addresses)
    deploy_hash       = filemd5("${path.module}/deploy.sh")
    port_guard_hash   = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
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

  # A directory only the deploy user can read, since provisioners can't set a
  # file's mode; deploy.sh empties it however it ends. The credentials go last,
  # so an upload that fails early leaves none behind.
  provisioner "remote-exec" {
    inline = ["install -d -m 0700 ${local.staged_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "${var.host.staging_dir}/auto-drive-auth-deploy.sh"
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

  provisioner "file" {
    content     = var.jwt_public_key
    destination = "${local.staged_dir}/jwt-public.pem"
  }

  provisioner "file" {
    content     = local.auth_env_file
    destination = "${local.staged_dir}/auth.env"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo DEPLOY_USER=${var.deployer.ssh_user} \
        DEPLOY_DIR=${local.deploy_dir} \
        STAGED_DIR=${local.staged_dir} \
        PRIVATE_ADDRESSES='${join(" ", var.private_addresses)}' \
        PORT_GUARD=${var.host.staging_dir}/compose-port-guard.py \
        bash ${var.host.staging_dir}/auto-drive-auth-deploy.sh
      EOT
    ]
  }

  depends_on = [terraform_data.wait_for]
}
