data "aws_caller_identity" "current" {}

################################################################################
# RDS Module
################################################################################

module "db" {
  source = "../templates/terraform/aws/rds/"

  identifier = local.name

  engine                   = "postgres"
  engine_version           = "16"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  family                   = "postgres16" # DB parameter group
  major_engine_version     = "16"         # DB option group
  instance_class           = "db.t4g.2xlarge"

  allocated_storage     = 50
  max_allocated_storage = 500


  db_name  = "postgres"
  username = "postgres"
  port     = 5432


  manage_master_user_password_rotation              = false
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [module.security_group.security_group_id]
  publicly_accessible    = false

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "auto-drive-db-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  cloudwatch_log_group_tags = {
    "Sensitive" = "high"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}

################################################################################
# RDS Automated Backups Replication Module
################################################################################

provider "aws" {
  alias  = "region2"
  region = local.region2
}

module "kms" {
  source      = "terraform-aws-modules/kms/aws"
  version     = "~> 1.0"
  description = "KMS key for cross region automated backups replication"

  # Aliases
  aliases                 = [local.name]
  aliases_use_name_prefix = true

  key_owners = [data.aws_caller_identity.current.arn]

  tags = local.tags

  providers = {
    aws = aws.region2
  }
}

module "db_automated_backups_replication" {
  source = "../templates/terraform/aws/rds/modules/db_instance_automated_backups_replication"

  source_db_instance_arn = module.db.db_instance_arn
  kms_key_arn            = module.kms.key_arn

  providers = {
    aws = aws.region2
  }
}

################################################################################
# Supporting Resources
################################################################################

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Auto Drive PostgreSQL security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}
