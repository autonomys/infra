resource "aws_iam_role" "vault-unseal" {
  name = "vault-unseal"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.openid.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(aws_iam_openid_connect_provider.openid.url, "https://", "")}:sub" : "system:serviceaccount:vault-server:vault"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "vault"
  }
}

resource "aws_iam_role_policy" "vault-unseal" {
  name = "vault-unseal"
  role = aws_iam_role.vault-unseal.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:GetRole",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:role/vault-unseal"
      },
      {
        Action = [
          "kms:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "vault" {
  name = "vault"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.openid.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(aws_iam_openid_connect_provider.openid.url, "https://", "")}:sub" : "system:serviceaccount:vault-server:boot-vault"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "vault"
  }
}

resource "aws_iam_role_policy" "vault" {
  name = "vault"
  role = aws_iam_role.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:vault-audit-logs"
      },
      {
        Action = [
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:vault-audit-logs:log-stream:*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:UpdateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.vault-secret.arn
      },
      {
        Action = [
          "iam:GetRole"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:role/vault"
      }
    ]
  })
}

resource "aws_kms_key" "vault-kms" {
  description             = "Vault Seal/Unseal key"
  deletion_window_in_days = 7

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Action": [
        "kms:*"
      ],
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Allow administration of the key",
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      "Principal": {
        "AWS": [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vault",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vault-unseal"
        ]
       }
    },
    {
      "Sid": "Allow use of the key",
      "Action": [
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext"
      ],
      "Principal": {
        "AWS": [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vault",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vault-unseal"
        ]
      },
      "Effect": "Allow",
      "Resource": "*"
    }
  ]

}
EOT
}

resource "random_string" "vault-secret-suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_secretsmanager_secret" "vault-secret" {
  name        = "vault-secret-${random_string.vault-secret-suffix.result}"
  kms_key_id  = aws_kms_key.vault-kms.key_id
  description = "Vault Root/Recovery key"
}

resource "aws_s3_bucket" "vault-scripts" {
  bucket = "bucket-${data.aws_caller_identity.current.account_id}-${var.region}-vault-scripts"
  acl    = "private"

  tags = {
    Name        = "Vault Scripts"
    Environment = "vault"
  }
}

resource "aws_s3_bucket_object" "vault-script-bootstrap" {
  bucket = aws_s3_bucket.vault-scripts.id
  key    = "scripts/bootstrap.sh"
  source = "scripts/bootstrap.sh"
  etag   = filemd5("scripts/bootstrap.sh")
}

resource "aws_s3_bucket_object" "vault-script-certificates" {
  bucket = aws_s3_bucket.vault-scripts.id
  key    = "scripts/certificates.sh"
  source = "scripts/certificates.sh"
  etag   = filemd5("scripts/certificates.sh")
}
