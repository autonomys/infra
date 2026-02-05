module "mainnet_chain_indexer" {
  source = "../../../modules/chain-indexer"
  aws = {
    secret              = var.aws_secret_key
    access_key          = var.aws_access_key
    vpc_id              = "mainnet-chain-indexer-vpc"
    vpc_cidr_block      = "172.33.0.0/16"
    region              = "us-east-1"
    availability_zone   = "us-east-1a"
    public_subnet_cidrs = "172.33.1.0/24"
    ssh_key_name        = var.aws_ssh_key_name
  }

  deployer = {
    ssh_user               = "ubuntu"
    ssh_agent_identity     = var.ssh_agent_identity
    path_to_scripts        = "../../../templates/scripts"
    path_to_docker_compose = "../../../modules/chain-indexer/docker-compose.yml"
  }

  instance = {
    network_name               = "mainnet"
    docker_tag                 = "sha-dfa9e28648df022762461c23ccffa30fa1bd062e"
    instance_type              = "c3.xlarge"
    disk_volume_size           = 500
    disk_volume_type           = "gp3"
    consensus_rpc              = "wss://rpc.mainnet.autonomys.xyz/ws"
    auto_evm_rpc               = "wss://auto-evm.mainnet.autonomys.xyz/ws"
    db_password                = var.db_password
    process_blocks_in_parallel = 400
  }
}
