module "chronos_chain_alerter" {
  source = "../../../modules/chain-alerts"
  aws = {
    secret              = var.aws_secret_key
    access_key          = var.aws_access_key
    vpc_id              = "chronos-chain-alerter-vpc"
    vpc_cidr_block      = "172.35.0.0/16"
    region              = "us-west-1"
    availability_zone   = "us-west-1a"
    public_subnet_cidrs = "172.35.1.0/24"
    ssh_key_name        = var.aws_ssh_key_name
  }

  deployer = {
    ssh_user               = "ubuntu"
    ssh_agent_identity     = var.ssh_agent_identity
    path_to_scripts        = "../../../templates/scripts"
    path_to_docker_compose = "../../../modules/chain-alerts/docker-compose.yml"
  }

  instance = {
    network_name   = "chronos"
    docker_tag     = "v0.2.1"
    instance_type  = "c3.xlarge"
    slack_secret   = var.slack_secret
    rpc_url        = "wss://rpc.chronos.autonomys.xyz/ws"
    uptimekuma_url = var.uptimekuma_url
  }
}
