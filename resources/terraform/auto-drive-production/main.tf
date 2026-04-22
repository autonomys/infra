module "auto_drive" {
  source = "../../../modules/auto-drive"

  providers = {
    aws         = aws
    aws.region2 = aws.region2
  }

  environment   = "prod"
  backup_region = var.backup_region

  vpc = {
    cidr            = "10.0.0.0/16"
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    az_count        = 3
  }

  rabbitmq = {
    instance_type   = "mq.m7g.medium"
    version         = "3.13"
    deployment_mode = "SINGLE_INSTANCE"
    username        = var.rabbitmq_username
  }

  instances = {
    backend_count         = 2
    backend_instance_type = "m7a.large"
    backend_names         = ["auto-drive-mainnet-private", "auto-drive-mainnet-public"]
    gateway_count         = 1
    gateway_instance_type = "m7a.large"
    gateway_names         = ["auto-drive-files-gateway-mainnet"]
    backend_volume_size   = 500
    gateway_volume_size   = 800
  }

  database = {
    instance_class    = "db.t4g.2xlarge"
    engine_version    = "17.4"
    allocated_storage = 50
    max_storage       = 500
    multi_az          = true
  }
}
