resource "random_password" "rabbitmq_password" {
  length           = 15
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>:?"
}

resource "aws_mq_broker" "rabbitmq_broker_primary" {
  broker_name                = "auto-drive-rabbitmq-broker-primary"
  engine_type                = "RabbitMQ"
  engine_version             = var.rabbitmq.version
  auto_minor_version_upgrade = true
  authentication_strategy    = "simple"
  host_instance_type         = var.rabbitmq.instance_type
  security_groups            = [aws_security_group.rabbitmq_broker_primary.id]
  deployment_mode            = var.rabbitmq.deployment_mode
  storage_type               = "ebs"
  apply_immediately          = true

  subnet_ids          = [element(module.vpc.private_subnets, 0)]
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
    username = var.rabbitmq.username
    password = random_password.rabbitmq_password.result
  }

  tags = {
    Environment = "Production"
    Application = "AutoDrive"
  }
}

resource "aws_security_group" "rabbitmq_broker_primary" {
  name        = "rabbitmq-primary-sg"
  description = "Security group for RabbitMQ primary broker"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5671
    to_port         = 5671
    protocol        = "tcp"
    security_groups = [aws_security_group.auto_drive_sg.id]
  }

  ingress {
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.auto_drive_sg.id]
  }

  ingress {
    from_port       = 15671
    to_port         = 15671
    protocol        = "tcp"
    security_groups = [aws_security_group.auto_drive_sg.id]
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

resource "aws_kms_key" "mq_kms_key" {
  description             = "KMS key for RabbitMQ encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "mq_kms_alias" {
  name          = "alias/rabbitmq-broker-key"
  target_key_id = aws_kms_key.mq_kms_key.id
}

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
