module "chronos_chain_indexer" {
  source = "../../../modules/chain-indexer"
  aws = {
    secret              = var.aws_secret_key
    access_key          = var.aws_access_key
    vpc_id              = "chronos-chain-indexer-vpc"
    vpc_cidr_block      = "172.39.0.0/16"
    region              = "us-west-2"
    availability_zone   = "us-west-2a"
    public_subnet_cidrs = "172.39.1.0/24"
    ssh_key_name        = var.aws_ssh_key_name
  }

  deployer = {
    ssh_user               = "ubuntu"
    ssh_agent_identity     = var.ssh_agent_identity
    path_to_scripts        = "../../../templates/scripts"
    path_to_docker_compose = "../../../modules/chain-indexer/docker-compose.yml"
  }

  instance = {
    network_name               = "chronos"
    domain_fqdn                = "autonomys.xyz"
    docker_tag                 = "sha-8700ea7598b2d3c92bbdffdb5596c3c9c8757f01"
    instance_type              = "c3.xlarge"
    disk_volume_size           = 500
    disk_volume_type           = "gp3"
    consensus_rpc              = "wss://rpc.chronos.autonomys.xyz/ws"
    auto_evm_rpc               = "wss://auto-evm.chronos.autonomys.xyz/ws"
    db_password                = var.db_password
    process_blocks_in_parallel = 400
  }

  cloudflare_api_token = var.cloudflare_api_token
}
