# IAM Role for Secrets Manager
resource "aws_iam_role" "auto_secret_role" {
  name = "AutoDriveSecretsManagerAppRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


# Policy to Access Secrets Manager
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "SecretsManagerReadPolicy"
  description = "Policy to allow reading the MainnetPublishingPrivateKey secret from AWS Secrets Manager"


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:MainnetPublishingPrivateKey"
      }
    ]
  })
}

# Attach Policy to IAM Role
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.auto_secret_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_instance_profile" "secrets_instance_profile" {
  name = "SecretsInstanceProfile"
  role = aws_iam_role.auto_secret_role.name
}
