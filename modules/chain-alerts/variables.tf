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
  })
}

variable "instance" {
  description = "Chain alerts specific details"
  type = object({
    network_name               = string
    docker_tag                 = string
    instance_type              = string
    rpc_url                    = string
    uptimekuma_url             = string
    slack_secret               = string
    slack_bot_name             = string
    slack_channel              = string
    non_block_import_threshold = string
    reorg_depth_threshold      = number
    per_slot_threshold         = string
    avg_slot_threshold         = string
  })
  sensitive = true
}
