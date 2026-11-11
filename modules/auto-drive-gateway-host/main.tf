locals {
  staging_dir = "/home/${var.deployer.ssh_user}/subspace"
  # the gateway repo's deploy playbook uses the same paths
  deploy_dir = "/home/${var.deployer.ssh_user}/deploy"

  # variable names are the ones the gateway's compose files and its Infisical
  # folders already use
  gateway_env = merge(var.settings, {
    NODE_DOCKER_TAG                   = var.images.node
    GATEWAY_DOCKER_TAG                = var.images.gateway
    FILE_RETRIEVER_DOCKER_TAG         = var.images.file_retriever
    OBJECT_MAPPING_INDEXER_DOCKER_TAG = var.images.object_mapping_indexer
    NETWORK_ID                        = var.network_id
    BLOCK_NUMBER_TO_START_FROM        = var.object_mapping_start_block
  })
  gateway_env_file = join("", [for k in sort(keys(local.gateway_env)) : "${k}=${local.gateway_env[k]}\n"])

  mesh_peer_rules = var.mesh == null ? [] : [
    for p in var.mesh.peers : { port = var.mesh.port, protocol = "udp", from = p.endpoint }
  ]
}

module "host" {
  source = "../host-bootstrap"

  deployer         = var.deployer
  host             = var.host
  public_tcp_ports = var.public_tcp_ports
  peer_rules       = concat(var.peer_rules, local.mesh_peer_rules)
}

module "mesh" {
  source = "../wireguard-mesh"
  count  = var.mesh == null ? 0 : 1

  deployer  = var.deployer
  host_ipv4 = var.host.ipv4
  mesh      = var.mesh

  depends_on = [module.host]
}

resource "null_resource" "deploy" {
  triggers = {
    bootstrap_id     = module.host.bootstrap_id
    ipv4             = var.host.ipv4
    gateway_repo     = var.gateway_repo
    gateway_repo_ref = var.gateway_repo_ref
    env_hash         = md5(local.gateway_env_file)
    services         = join(" ", var.services)
    compose_files    = join(" ", var.compose_files)
    compose_project  = var.compose_project
    compose_profiles = join(" ", var.compose_profiles)
    public_tcp_ports = join(" ", var.public_tcp_ports)
    deploy_hash      = filemd5("${path.module}/deploy.sh")
  }

  connection {
    host           = var.host.ipv4
    user           = var.deployer.ssh_user
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  provisioner "file" {
    content     = local.gateway_env_file
    destination = "${local.staging_dir}/auto-files-gateway.env"
  }

  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "${local.staging_dir}/auto-drive-gateway-deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo DEPLOY_USER=${var.deployer.ssh_user} \
        DEPLOY_DIR=${local.deploy_dir} \
        GATEWAY_REPO=${var.gateway_repo} \
        GATEWAY_REPO_REF=${var.gateway_repo_ref} \
        GATEWAY_ENV_SRC=${local.staging_dir}/auto-files-gateway.env \
        COMPOSE_PROJECT=${var.compose_project} \
        COMPOSE_FILES='${join(" ", var.compose_files)}' \
        COMPOSE_PROFILES='${join(" ", var.compose_profiles)}' \
        SERVICES='${join(" ", var.services)}' \
        PUBLIC_TCP_PORTS='${join(" ", var.public_tcp_ports)}' \
        bash ${local.staging_dir}/auto-drive-gateway-deploy.sh
      EOT
    ]
  }

  depends_on = [module.mesh]
}
