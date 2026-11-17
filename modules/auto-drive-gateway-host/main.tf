locals {
  staging_dir = module.host.staging_dir
  staged_dir  = "${local.staging_dir}/auto-drive-gateway"
  deploy_dir  = "/home/${var.deployer.ssh_user}/deploy/auto-drive-gateway"

  # every file in compose/ is uploaded and installed, and counts towards the
  # trigger; COMPOSE_FILE picks the compose files in use
  compose_dir = "${path.module}/compose"
  compose_files = concat(
    ["docker-compose.yml"],
    var.mesh == null ? [] : ["docker-compose.mesh.yml"],
    var.cap_local_logs ? ["docker-compose.log-cap.yml"] : [],
    var.dag_indexer == null ? [] : ["docker-compose.dag-indexer.yml"],
  )

  backup_dir = "/var/backups/auto-drive-gateway"
  dag_indexer_env = var.dag_indexer == null ? {} : {
    DAG_INDEXER_DOCKER_TAG       = var.dag_indexer.image
    GATEWAY_DB_BACKUP_DOCKER_TAG = var.dag_indexer.backup_image
    DAG_INDEXER_START_GUARD_ID   = filesha1("${local.compose_dir}/dag-indexer-start-guard.js")
    GATEWAY_DB_SCRIPT_ID         = filesha1("${local.compose_dir}/gateway-db.sh")
    BACKUP_DIR                   = local.backup_dir
  }
  # for one deploy each; see the variables
  accept_rewind_to     = var.dag_indexer == null ? "" : (var.dag_indexer.accept_rewind_to == null ? "" : tostring(var.dag_indexer.accept_rewind_to))
  accept_schema_sha256 = var.dag_indexer == null ? "" : var.dag_indexer.accept_schema_sha256

  # Compose reads this from the deploy directory, so `docker compose` run there
  # by hand sees the same project, files and values as the deploy
  env = merge({
    COMPOSE_PROJECT_NAME              = var.compose_project
    COMPOSE_FILE                      = join(":", local.compose_files)
    NODE_DOCKER_TAG                   = var.images.node
    GATEWAY_DOCKER_TAG                = var.images.gateway
    OBJECT_MAPPING_INDEXER_DOCKER_TAG = var.images.object_mapping_indexer
    FILE_RETRIEVER_DOCKER_TAG         = var.images.file_retriever
    DATABASE_ID                       = var.database_id
    NETWORK_ID                        = var.network_id
    BLOCK_NUMBER_TO_START_FROM        = var.create_object_mappings
    RUST_LOG_NODE                     = var.node_rust_log
    OUT_CONNECTIONS                   = var.rpc_gateway.out_connections
    PENDING_OUT_CONNECTIONS           = var.rpc_gateway.pending_out_connections
    RUST_LOG_GATEWAY                  = var.rpc_gateway.rust_log
    LOG_LEVEL                         = var.log_level
    REQUEST_SIZE_LIMIT                = var.object_mapping.request_size_limit
    CORS_ALLOW_ORIGINS                = var.object_mapping.cors_allow_origins
    RECOVERY_INTERVAL                 = var.object_mapping.recovery_interval
    CORS_ORIGIN                       = var.file_retriever.cors_origin
    MAX_SIMULTANEOUS_FETCHES          = var.file_retriever.max_simultaneous_fetches
    CACHE_MAX_SIZE                    = var.file_retriever.cache_max_size
    CACHE_TTL                         = var.file_retriever.cache_ttl
    METRIC_ENVIRONMENT_TAG            = coalesce(var.file_retriever.metric_environment_tag, "chain=${var.network_id}")
    VICTORIA_ACTIVE                   = var.metrics == null ? "false" : "true"
    VICTORIA_ENDPOINT                 = var.metrics == null ? "" : var.metrics.endpoint
    VICTORIA_USERNAME                 = var.metrics == null ? "" : var.metrics.username
    LOKI_URL                          = var.loki_url
  }, var.mesh == null ? {} : { MESH_ADDRESS = var.mesh.address }, local.dag_indexer_env)
  # single-quoted, so Compose takes each value literally instead of expanding a
  # $ in it; the precondition below keeps quotes and line breaks out of them
  env_file = join("", [for k in keys(local.env) : "${k}='${local.env[k]}'\n"])

  database_url = "postgres://${var.database.user}:${var.database_password}@${var.database.host}:${var.database.port}/${var.database.name}"
  secrets = {
    "object-mapping-indexer.env" = { DATABASE_URL = local.database_url }
    "file-retriever.env" = {
      DATABASE_URL      = local.database_url
      API_SECRET        = var.api_secret
      VICTORIA_PASSWORD = var.metrics_password
    }
    # the DAG indexer's and the backups', in the names the indexer reads
    "gateway-db.env" = {
      DB_HOST     = var.database.host
      DB_PORT     = var.database.port
      DB_DATABASE = var.database.name
      DB_USER     = var.database.user
      DB_PASS     = var.database_password
    }
  }
  secret_files = { for f, vars in local.secrets : f => join("", [for k in keys(vars) : "${k}='${vars[k]}'\n"]) }
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

# Holds wait_for, so that the deploy, which depends on this, runs after
# whatever produced those IDs
resource "terraform_data" "wait_for" {
  input = var.wait_for
}

resource "null_resource" "deploy" {
  # hashes only for the secrets: the credentials themselves never reach the state
  triggers = {
    bootstrap_id     = module.host.bootstrap_id
    ipv4             = var.host.ipv4
    ssh_user         = var.deployer.ssh_user
    compose_hash     = sha1(join("", [for f in sort(fileset(local.compose_dir, "*")) : "${f}:${filesha1("${local.compose_dir}/${f}")}\n"]))
    env_hash         = md5(local.env_file)
    secrets_hash     = nonsensitive(sha256(join("", [for f in sort(keys(local.secret_files)) : local.secret_files[f]])))
    public_tcp_ports = join(" ", var.public_tcp_ports)
    mesh_address     = var.mesh == null ? "" : var.mesh.address
    deploy_hash      = filemd5("${path.module}/deploy.sh")
    port_guard_hash  = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
    overrides        = "start_empty=${var.database_start_empty} accept_rewind_to=${local.accept_rewind_to} accept_schema_sha256=${local.accept_schema_sha256}"
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for v in concat(values(local.env), flatten([for vars in values(local.secrets) : values(vars)])) :
        !strcontains(v, "'") && !strcontains(v, "\n")
      ])
      error_message = "A value for the gateway's .env or env files contains a single quote or a line break, which their quoting can't hold."
    }
    precondition {
      condition     = alltrue([for f in local.compose_files : fileexists("${local.compose_dir}/${f}")])
      error_message = "COMPOSE_FILE names a file that is not in the module's compose/ directory."
    }
    precondition {
      condition     = var.metrics == null || var.metrics_password != ""
      error_message = "metrics is set but metrics_password is empty, which would push metrics with no credentials."
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

  # the credentials go last, so an upload that fails early leaves none behind
  provisioner "file" {
    content     = local.secret_files["object-mapping-indexer.env"]
    destination = "${local.staged_dir}/object-mapping-indexer.env"
  }

  provisioner "file" {
    content     = local.secret_files["file-retriever.env"]
    destination = "${local.staged_dir}/file-retriever.env"
  }

  provisioner "file" {
    content     = local.secret_files["gateway-db.env"]
    destination = "${local.staged_dir}/gateway-db.env"
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
        BACKUP_DIR=${local.backup_dir} \
        START_EMPTY='${var.database_start_empty}' \
        ACCEPT_REWIND_TO=${local.accept_rewind_to} \
        ACCEPT_SCHEMA_SHA256=${local.accept_schema_sha256} \
        bash ${local.staging_dir}/auto-drive-gateway-deploy.sh
      EOT
    ]
  }

  depends_on = [module.mesh, terraform_data.wait_for]
}
