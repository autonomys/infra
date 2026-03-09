################################################################################
# State migration: VPC
################################################################################

moved {
  from = module.vpc
  to   = module.auto_drive.module.vpc
}

################################################################################
# State migration: Security Groups
################################################################################

moved {
  from = aws_security_group.auto_drive_sg
  to   = module.auto_drive.aws_security_group.auto_drive_sg
}

moved {
  from = aws_security_group.rabbitmq_broker_primary
  to   = module.auto_drive.aws_security_group.rabbitmq_broker_primary
}

################################################################################
# State migration: RabbitMQ Broker
################################################################################

moved {
  from = random_password.rabbitmq_password
  to   = module.auto_drive.random_password.rabbitmq_password
}

moved {
  from = aws_mq_broker.rabbitmq_broker_primary
  to   = module.auto_drive.aws_mq_broker.rabbitmq_broker_primary
}

################################################################################
# State migration: RabbitMQ KMS
################################################################################

moved {
  from = aws_kms_key.mq_kms_key
  to   = module.auto_drive.aws_kms_key.mq_kms_key
}

moved {
  from = aws_kms_alias.mq_kms_alias
  to   = module.auto_drive.aws_kms_alias.mq_kms_alias
}

################################################################################
# State migration: RabbitMQ CloudWatch IAM
################################################################################

moved {
  from = aws_iam_role.mq_cloudwatch_role
  to   = module.auto_drive.aws_iam_role.mq_cloudwatch_role
}

moved {
  from = aws_iam_policy.mq_cloudwatch_policy
  to   = module.auto_drive.aws_iam_policy.mq_cloudwatch_policy
}

moved {
  from = aws_iam_role_policy_attachment.mq_cloudwatch_attach
  to   = module.auto_drive.aws_iam_role_policy_attachment.mq_cloudwatch_attach
}

################################################################################
# State migration: EC2 Instances
################################################################################

moved {
  from = module.ec2_auto_drive
  to   = module.auto_drive.module.ec2_backend
}

moved {
  from = module.ec2_gateway
  to   = module.auto_drive.module.ec2_gateway
}

################################################################################
# State migration: RDS
################################################################################

moved {
  from = module.db
  to   = module.auto_drive.module.db
}

moved {
  from = aws_db_subnet_group.db_subnet_group
  to   = module.auto_drive.aws_db_subnet_group.db_subnet_group
}

moved {
  from = module.kms
  to   = module.auto_drive.module.kms
}

moved {
  from = module.db_automated_backups_replication
  to   = module.auto_drive.module.db_automated_backups_replication
}

moved {
  from = module.security_group
  to   = module.auto_drive.module.db_security_group
}

################################################################################
# State migration: Secrets Manager IAM
################################################################################

moved {
  from = aws_iam_role.auto_secret_role
  to   = module.auto_drive.aws_iam_role.auto_secret_role
}

moved {
  from = aws_iam_policy.secrets_manager_policy
  to   = module.auto_drive.aws_iam_policy.secrets_manager_policy
}

moved {
  from = aws_iam_role_policy_attachment.attach_policy
  to   = module.auto_drive.aws_iam_role_policy_attachment.attach_policy
}

moved {
  from = aws_iam_instance_profile.secrets_instance_profile
  to   = module.auto_drive.aws_iam_instance_profile.secrets_instance_profile
}
