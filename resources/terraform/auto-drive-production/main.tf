module "auto_drive" {
  source = "../../../modules/auto-drive"

  environment   = "prod"
  region        = var.region
  backup_region = "us-west-1"

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
}
