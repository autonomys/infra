locals {
  staging_dir = module.host.staging_dir
  staged_dir  = "${local.staging_dir}/auto-drive"
  # production's path, beside its project name
  deploy_dir = "/home/${var.deployer.ssh_user}/deploy/auto-drive"

  # every .yml in compose/ is uploaded and installed, and only those count
  # towards the trigger; COMPOSE_FILE picks the ones in use
  compose_dir   = "${path.module}/compose"
  compose_files = concat(["docker-compose.yml"], var.cap_local_logs ? ["docker-compose.log-cap.yml"] : [])

  # the services each profile starts, as the compose file assigns them
  profile_services = {
    base              = ["hasura"]
    frontend          = ["backend-worker", "backend-publish-worker", "backend-api"]
    "frontend-api"    = ["backend-api"]
    "frontend-worker" = ["backend-worker", "backend-publish-worker"]
    download          = ["backend-download-worker", "backend-download-api"]
    "download-api"    = ["backend-download-api"]
    "download-worker" = ["backend-download-worker"]
  }
  services = distinct(flatten([for p in var.profiles : local.profile_services[p]]))
  service_ports = {
    "hasura"                  = var.ports.hasura
    "backend-api"             = var.ports.backend_api
    "backend-worker"          = var.ports.backend_worker
    "backend-publish-worker"  = var.ports.backend_publish_worker
    "backend-download-api"    = var.ports.backend_download_api
    "backend-download-worker" = var.ports.backend_download_worker
  }
  ports = { for s in local.services : s => local.service_ports[s] }
  # the API the site's /api and file routes reach
  api_service = var.ingress.site == "public" ? "backend-download-api" : "backend-api"

  # Compose reads this from the deploy directory, both to fill in the compose
  # file and, through env_file, as the backend services' environment, as on
  # production's hosts. `docker compose` run there by hand sees what the deploy
  # does.
  module_env = {
    COMPOSE_PROJECT_NAME          = var.compose_project
    COMPOSE_FILE                  = join(":", local.compose_files)
    COMPOSE_PROFILES              = join(",", var.profiles)
    BACKEND_IMAGE                 = var.images.backend
    HASURA_IMAGE                  = var.images.hasura
    HASURA_ASSET_DIRS             = var.hasura.apply_sql_migrations ? "apps/hasura/metadata apps/hasura/migrations" : "apps/hasura/metadata"
    DATABASE_ID                   = var.database_id
    PUBLISH_ADDRESS               = var.publish_address
    LOKI_URL                      = var.loki_url
    HASURA_GRAPHQL_PORT           = var.ports.hasura
    BACKEND_API_PORT              = var.ports.backend_api
    BACKEND_WORKER_PORT           = var.ports.backend_worker
    BACKEND_PUBLISH_WORKER_PORT   = var.ports.backend_publish_worker
    BACKEND_DOWNLOAD_API_PORT     = var.ports.backend_download_api
    BACKEND_DOWNLOAD_WORKER_PORT  = var.ports.backend_download_worker
    HASURA_GRAPHQL_ENABLE_CONSOLE = tostring(var.hasura.enable_console)
    HASURA_GRAPHQL_CORS_DOMAIN    = var.hasura.cors_domain
    HASURA_GRAPHQL_JWT_SECRET     = jsonencode({ type = "RS256", key = var.hasura.jwt_public_key })
    HASURA_GRAPHQL_ADMIN_SECRET   = var.hasura_admin_secret
    DATABASE_URL                  = var.database_url
    RABBITMQ_URL                  = var.rabbitmq_url
    RPC_ENDPOINT                  = var.endpoints.rpc
    OBJECT_MAPPING_ARCHIVER_URL   = var.endpoints.object_mapping_archiver
    FILES_GATEWAY_URL             = var.endpoints.files_gateway
    AUTH_SERVICE_URL              = var.endpoints.auth_service
    EVM_CHAIN_ENDPOINT            = var.endpoints.evm_chain
    AUTH_SERVICE_API_KEY          = var.secrets.auth_service_api_key
    FILES_GATEWAY_TOKEN           = var.secrets.files_gateway_token
  }
  env_values = merge(var.settings, var.secrets.extra, local.module_env)
  # single-quoted, so Compose takes every value literally
  env_file = join("", [for k in sort(keys(local.env_values)) : "${k}='${local.env_values[k]}'\n"])

  # read by `docker run --env-file`, which takes values as written, unquoted
  migrate_env = "DATABASE_URL=${coalesce(var.migration_database_url, var.database_url)}\n"

  cert_name    = var.ingress.hostnames.app
  cert_domains = compact([var.ingress.hostnames.app, var.ingress.hostnames.s3])
  nginx_conf = templatefile("${path.module}/nginx.conf.tftpl", {
    real_ip_from = var.ingress.real_ip_from
  })
  site = { for stage, tls in { bootstrap = false, tls = true } : stage => templatefile("${path.module}/site-${var.ingress.site}.conf.tftpl", {
    tls               = tls
    app_host          = var.ingress.hostnames.app
    s3_host           = var.ingress.hostnames.s3
    gateway_host      = var.ingress.hostnames.gateway
    cert_name         = local.cert_name
    root_redirect_url = var.ingress.root_redirect_url
    upstream          = var.publish_address
    api_port          = lookup(local.ports, local.api_service, 0)
    hasura_port       = lookup(local.ports, "hasura", 0)
  }) }
}

module "host" {
  source = "../host-bootstrap"

  deployer         = var.deployer
  host             = var.host
  public_tcp_ports = [80, 443]
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

# Holds wait_for, so that the migrations and the deploy, which depend on this,
# run after whatever produced those IDs
resource "terraform_data" "wait_for" {
  input = var.wait_for
}

resource "null_resource" "migrate" {
  count = var.run_migrations ? 1 : 0

  # hashes only: the database credentials never reach the state
  triggers = {
    bootstrap_id     = module.host.bootstrap_id
    ipv4             = var.host.ipv4
    ssh_user         = var.deployer.ssh_user
    backend_image    = var.images.backend
    database_id      = var.database_id
    migrate_env_hash = nonsensitive(sha256(local.migrate_env))
    migrate_hash     = filemd5("${path.module}/migrate.sh")
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
    inline = ["install -d -m 0700 ${local.staged_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/migrate.sh"
    destination = "${local.staging_dir}/auto-drive-migrate.sh"
  }

  provisioner "file" {
    content     = local.migrate_env
    destination = "${local.staged_dir}/migrate.env"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo DEPLOY_USER=${var.deployer.ssh_user} \
        DEPLOY_DIR=${local.deploy_dir} \
        MIGRATE_ENV=${local.staged_dir}/migrate.env \
        BACKEND_IMAGE=${var.images.backend} \
        bash ${local.staging_dir}/auto-drive-migrate.sh
      EOT
    ]
  }

  depends_on = [module.mesh, terraform_data.wait_for]
}

resource "null_resource" "deploy" {
  # hashes only: the credentials themselves never reach the state
  triggers = {
    bootstrap_id    = module.host.bootstrap_id
    ipv4            = var.host.ipv4
    ssh_user        = var.deployer.ssh_user
    migrate_id      = join("", null_resource.migrate[*].id)
    compose_hash    = sha1(join("", [for f in sort(fileset(local.compose_dir, "*.yml")) : "${f}:${filesha1("${local.compose_dir}/${f}")}\n"]))
    env_hash        = nonsensitive(sha256(local.env_file))
    nginx_conf_hash = md5(local.nginx_conf)
    site_hash       = md5(join("", values(local.site)))
    cert            = join(" ", concat(local.cert_domains, [var.ingress.letsencrypt.email, tostring(var.ingress.letsencrypt.staging)]))
    deploy_hash     = filemd5("${path.module}/deploy.sh")
    port_guard_hash = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
  }

  lifecycle {
    precondition {
      condition     = length(distinct(values(local.ports))) == length(local.ports)
      error_message = "Two running services would publish the same host port; set ports so each is distinct."
    }

    precondition {
      condition     = contains(local.services, local.api_service) && contains(local.services, "hasura")
      error_message = "The site routes /hasura and /api: a public one needs the base and download (or download-api) profiles, a private one base and frontend (or frontend-api)."
    }

    precondition {
      condition     = alltrue([for f in local.compose_files : fileexists("${local.compose_dir}/${f}")])
      error_message = "COMPOSE_FILE names a file that is not in the module's compose/ directory."
    }

    precondition {
      condition     = nonsensitive(alltrue([for v in values(local.env_values) : !strcontains(tostring(v), "'")]))
      error_message = "A value for the .env contains a single quote, which its quoting can't hold."
    }

    precondition {
      condition = (
        length(setintersection(keys(var.settings), keys(local.module_env))) == 0
        && length(setintersection(nonsensitive(keys(var.secrets.extra)), concat(keys(var.settings), keys(local.module_env)))) == 0
      )
      error_message = "settings or secrets.extra repeat a key the module sets itself, or each other."
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
  # mode; deploy.sh empties it however it ends. The .env, which holds the
  # credentials, goes last, so an upload that fails early leaves none behind.
  provisioner "remote-exec" {
    inline = ["install -d -m 0700 ${local.staged_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "${local.staging_dir}/auto-drive-deploy.sh"
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
    content     = local.nginx_conf
    destination = "${local.staged_dir}/nginx.conf"
  }

  provisioner "file" {
    content     = local.site.bootstrap
    destination = "${local.staged_dir}/site-bootstrap.conf"
  }

  provisioner "file" {
    content     = local.site.tls
    destination = "${local.staged_dir}/site.conf"
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
        PRIVATE_ADDRESSES='${var.mesh == null ? "" : var.mesh.address}' \
        PORT_GUARD=${local.staging_dir}/compose-port-guard.py \
        CERT_NAME=${local.cert_name} \
        CERT_DOMAINS='${join(" ", local.cert_domains)}' \
        LE_EMAIL='${var.ingress.letsencrypt.email}' \
        LE_STAGING=${var.ingress.letsencrypt.staging} \
        bash ${local.staging_dir}/auto-drive-deploy.sh
      EOT
    ]
  }

  depends_on = [module.mesh, terraform_data.wait_for, null_resource.migrate]
}
