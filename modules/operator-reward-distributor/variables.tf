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

variable "deployer" {
  description = "Deployer specific details"
  type = object({
    ssh_user               = string
    ssh_agent_identity     = string
    path_to_scripts        = string
    path_to_docker_compose = string
    path_to_nginx_conf     = string
  })
}

variable "instance" {
  description = "Chain alerts specific details"
  type = object({
    network_name        = string
    docker_tag          = string
    instance_type       = string
    rpc_url             = string
    interval_seconds    = number
    tip_ai3             = number
    daily_ai3_cap       = number
    max_retries         = number
    mortality_blocks    = number
    confirmation_blocks = number
    account_private_key = string
  })
  sensitive = true
}
