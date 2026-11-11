module "files_gateway" {
  source = "../../../modules/auto-drive-gateway-host"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  host = {
    ipv4     = var.gateway_host_ipv4
    hostname = "auto-drive-files-gateway-chronos"
  }

  network_id                 = "chronos"
  object_mapping_start_block = "1"

  # autonomys/auto-files-gateway main as of 2026-11-09
  gateway_repo_ref = "7c5093bd26c399e7e6f484cfc9e27b59f2ea04a2"

  # file_retriever and object_mapping_indexer are not started yet
  images = {
    node                   = "ghcr.io/autonomys/node:mainnet-2026-jan-20"
    gateway                = "ghcr.io/autonomys/gateway:mainnet-2026-oct-22"
    file_retriever         = "ghcr.io/autonomys/file-retriever:latest"
    object_mapping_indexer = "ghcr.io/autonomys/object-mapping-indexer:latest"
  }

  services = ["subspace-node"]
}
