module "network" {
  source          = "../base"
  path_to_scripts = "../base/scripts"
  network_name    = var.network_name

  bootstrap-node-config = {
    deployment-version  = 1
    instance-count      = var.instance_count["bootstrap"]
    docker-org          = "subspace"
    docker-tag          = "bootstrap-node"
    additional-node-ips = var.additional_node_ips["bootstrap"]
    reserved-only       = true
    prune               = false
    genesis-hash        = ""
    dsn-listen-port     = 30533
    node-dsn-port       = 30433
  }

  node-config = {
    deployment-version  = 1
    instance-count      = var.instance_count["node"]
    docker-org          = "subspace"
    docker-tag          = "subspace-node"
    additional-node-ips = var.additional_node_ips["node"]
    reserved-only       = true
    prune               = false
    node-dsn-port       = 30433
  }

  domain-node-config = {
    deployment-version  = 1
    instance-count      = var.instance_count["domain"]
    docker-org          = "subspace"
    docker-tag          = "subspace-node"
    additional-node-ips = var.additional_node_ips["domain"]
    domain-prefix       = "domain"
    reserved-only       = true
    prune               = false
    node-dsn-port       = 30434
    enable-domains      = true
    domain-id           = var.domain_id
    domain-labels       = var.domain_labels
  }

  farmer-node-config = {
    deployment-version     = 1
    instance-count         = var.instance_count["farmer"]
    docker-org             = "subspace"
    docker-tag             = "farmer-node"
    additional-node-ips    = var.additional_node_ips["farmer"]
    reserved-only          = true
    prune                  = false
    plot-size              = "10G"
    reward-address         = var.farmer_reward_address
    force-block-production = true
    node-dsn-port          = 30433

  }

  tf_token         = var.tf_token
  private_key_path = var.private_key_path
  branch_name      = var.branch_name
  ssh_key_name     = var.ssh_key_name
  ssh_user         = var.ssh_user

}
