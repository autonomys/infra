resource "random_password" "rabbitmq_password" {
  length           = 15
  special          = true # Includes special characters
  override_special = "!@#$%^&*()-_=+[]{}<>:?"
}

variable "private_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "aws_mq_broker" "rabbitmq_broker_primary" {
  broker_name                = "auto-drive-rabbitmq-broker-primary"
  engine_type                = "RabbitMQ"
  engine_version             = var.rabbitmq_version
  auto_minor_version_upgrade = true
  authentication_strategy    = "simple"
  host_instance_type         = var.rabbitmq_instance_type # t3.micro is the smallest instance type available for Amazon MQ, use mq.m5.large for production
  security_groups            = [aws_security_group.rabbitmq_broker_primary.id]
  deployment_mode            = var.rabbitmq_deployment_mode_staging # change to CLUSTER_MULTI_AZ for production
  storage_type               = "ebs"
  apply_immediately          = true

  subnet_ids          = [element(module.vpc.private_subnets, 0)] # Use private subnets from VPC module, in single AZ deployment, use only one subnet, in multi-AZ deployment, use multiple subnets
  publicly_accessible = false
  encryption_options {
    use_aws_owned_key = false
    kms_key_id        = aws_kms_key.mq_kms_key.arn
  }

  logs {
    general = true
    audit   = false
  }

  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "03:00"
    time_zone   = "UTC"
  }

  user {
    username = var.rabbitmq_username
    password = random_password.rabbitmq_password.result
  }

  tags = {
    Environment = "Production"
    Application = "AutoDrive"
  }
}

# Data replication is only supported for activemq engine currently.
# resource "aws_mq_broker" "rabbitmq_broker_secondary" {
#   broker_name                = "auto-drive-rabbitmq-broker-secondary"
#   engine_type                = "RabbitMQ"
#   engine_version             = var.rabbitmq_version
#   auto_minor_version_upgrade = true
#   authentication_strategy    = "simple"
#   host_instance_type         = var.rabbitmq_instance_type # t3.micro is the smallest instance type available for Amazon MQ, use mq.m5.large for production
#   security_groups            = [aws_security_group.rabbitmq_broker_secondary.id]
#   deployment_mode            = var.rabbitmq_deployment_mode_staging # change to CLUSTER_MULTI_AZ for production
#   storage_type               = "ebs"
#   apply_immediately          = true

#   data_replication_mode               = "CRDR"
#   data_replication_primary_broker_arn = aws_mq_broker.rabbitmq_broker_primary.arn

#   subnet_ids          = [element(module.vpc.private_subnets, 0)] # Use private subnets from VPC module, in single AZ deployment, use only one subnet, in multi-AZ deployment, use multiple subnets
#   publicly_accessible = false
#   encryption_options {
#     use_aws_owned_key = false
#     kms_key_id        = aws_kms_key.mq_kms_key.arn
#   }

#   logs {
#     general = true
#     audit   = false
#   }

#   maintenance_window_start_time {
#     day_of_week = "Sunday"
#     time_of_day = "04:00"
#     time_zone   = "UTC"
#   }

#   user {
#     username         = var.rabbitmq_replication_username
#     password         = random_password.rabbitmq_password.result
#     replication_user = true
#   }

#   tags = {
#     Environment = "Production"
#     Application = "AutoDrive"
#   }
# }

# Security Group for RabbitMQ Primary Broker
resource "aws_security_group" "rabbitmq_broker_primary" {
  name        = "rabbitmq-primary-sg"
  description = "Security group for RabbitMQ primary broker"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rabbitmq-primary-sg"
  }
}

# Data replication is only supported for activemq engine currently.
# Security Group for RabbitMQ Secondary Broker
# resource "aws_security_group" "rabbitmq_broker_secondary" {
#   name        = "rabbitmq-secondary-sg"
#   description = "Security group for RabbitMQ secondary broker"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 5671
#     to_port     = 5671
#     protocol    = "tcp"
#     cidr_blocks = var.private_subnet_cidrs
#   }

#   ingress {
#     from_port   = 5672
#     to_port     = 5672
#     protocol    = "tcp"
#     cidr_blocks = var.private_subnet_cidrs
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "rabbitmq-secondary-sg"
#   }
# }

# KMS Key for Encryption
resource "aws_kms_key" "mq_kms_key" {
  description             = "KMS key for RabbitMQ encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "mq_kms_alias" {
  name          = "alias/rabbitmq-broker-key"
  target_key_id = aws_kms_key.mq_kms_key.id
}

# IAM Role for CloudWatch Logging
resource "aws_iam_role" "mq_cloudwatch_role" {
  name               = "mq-cloudwatch-logs-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "mq.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "mq_cloudwatch_policy" {
  name        = "mq-cloudwatch-logs-policy"
  description = "Policy for allowing Amazon MQ to write logs to CloudWatch"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "mq_cloudwatch_attach" {
  role       = aws_iam_role.mq_cloudwatch_role.name
  policy_arn = aws_iam_policy.mq_cloudwatch_policy.arn
}
