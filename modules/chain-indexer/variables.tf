variable "aws" {
  description = "AWS specific details"
  type = object({
    secret              = string
    access_key          = string
    vpc_id              = string
    vpc_cidr_block      = string
    region              = string
    availability_zone   = string
    public_subnet_cidrs = string
    ssh_key_name        = string
  })
  sensitive = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare api token"
  type        = string
}

variable "deployer" {
  description = "Deployer specific details"
  type = object({
    ssh_user               = string
    ssh_agent_identity     = string
    path_to_scripts        = string
    path_to_docker_compose = string
  })
}

variable "instance" {
  description = "Chain alerts specific details"
  type = object({
    network_name               = string
    domain_fqdn                = string
    docker_tag                 = string
    instance_type              = string
    disk_volume_size           = number
    disk_volume_type           = string
    consensus_rpc              = string
    auto_evm_rpc               = string
    db_password                = string
    process_blocks_in_parallel = number
  })
}
