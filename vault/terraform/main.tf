resource "aws_s3_bucket" "vault_storage" {
  bucket        = "vault-subspace-network"
  force_destroy = true
  #  acl = "private"
  depends_on = [
    aws_iam_user.vault,
    aws_kms_key.vault
  ]

  # Enable MFA delete protection
  lifecycle {
    prevent_destroy = false
  }
}

# resource "aws_s3_bucket_acl" "acl_vault_storage" {
#   bucket = aws_s3_bucket.vault_storage.id
#   acl    = "private"
# }

resource "aws_s3_bucket_versioning" "versioning_vault_storage" {
  bucket = aws_s3_bucket.vault_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_user" "vault" {
  name = "vault-admin"

  tags = {
    Name = "Vault IAM User"
  }
}

resource "aws_iam_access_key" "vault" {
  user = aws_iam_user.vault.name
}

resource "aws_iam_instance_profile" "vault" {
  name = "vault-instance-profile"
  role = aws_iam_role.vault.name
}

resource "aws_iam_role" "vault" {
  name               = "vault-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "vault" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.vault.arn
}

resource "aws_iam_policy" "vault" {
  name        = "vault-policy"
  description = "Policy for Vault backend access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucketVersions"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.vault_storage.bucket}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.vault_storage.bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "vault" {
  user       = aws_iam_user.vault.name
  policy_arn = aws_iam_policy.vault.arn
  depends_on = [aws_iam_policy.vault]
}

resource "aws_kms_key" "vault" {
  description             = "Vault encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "vault" {
  name          = "alias/vault-key"
  target_key_id = aws_kms_key.vault.key_id
}

resource "aws_security_group_rule" "vault_http" {
  security_group_id = aws_security_group.vault_sg.id
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Restrict the CIDR block as needed
}

resource "aws_instance" "vault" {
  ami                         = data.aws_ami.ubuntu_x86.id # Update with the desired Vault AMI ID
  instance_type               = var.vault_instance_type    # Update with the desired instance type
  key_name                    = var.ssh_key_name           # Update with your SSH key pair
  subnet_id                   = aws_subnet.vault_subnet.id
  availability_zone           = var.aws_az
  associate_public_ip_address = true

  # Attach the IAM role to the instance
  iam_instance_profile = aws_iam_instance_profile.vault.name

  vpc_security_group_ids = [aws_security_group.vault_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get install -y nginx unzip certbot
              cat <<EOF-n > /etc/nginx/conf.d/vault.conf
              server {
                listen 80;
                server_name vault.subspace.network;
                location / {
                  proxy_pass http://127.0.0.1:8200;
                  proxy_set_header Host \$host;
                  proxy_set_header X-Real-IP \$remote_addr;
                  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto \$scheme;
                }
              }
              EOF-n
              sudo certbot nginx --non-interactive --agree-tos --email alert@subspace.network -d vault.subspace.network
              sudo systemctl restart nginx
              echo "export VAULT_ADDR=http://localhost:8200" >> /etc/environment
              echo "export VAULT_SKIP_VERIFY=true" >> /etc/environment
              echo "export vault_storage=s3" >> /etc/environment
              echo "export VAULT_BUCKET=${aws_s3_bucket.vault_storage.bucket}" >> /etc/environment
              echo "export VAULT_BUCKET_REGION=${var.aws_region}" >> /etc/environment
              echo "export AWS_ACCESS_KEY_ID=${aws_iam_access_key.vault.id}" >> /etc/environment
              echo "export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.vault.secret}" >> /etc/environment
              echo "export VAULT_KMS_KEY_ID=${aws_kms_alias.vault.target_key_id}" >> /etc/environment
              echo "export VAULT_TLS_DISABLE=true" >> /etc/environment

              curl -LO https://releases.hashicorp.com/vault/1.13.2/vault_1.13.2_linux_amd64.zip
              unzip vault_1.13.2_linux_amd64.zip
              mv vault /usr/local/bin/
              chmod +x /usr/local/bin/vault
              # Configure Vault server
              cat > vault-config.hcl <<EOF2
              storage "s3" {
                bucket      = "${aws_s3_bucket.vault_storage.bucket}"
                region      = "${var.aws_region}"  # Replace with your desired region
                access_key  = "${aws_iam_access_key.vault.id}"
                secret_key  = "${aws_iam_access_key.vault.secret}"
              }
              listener "tcp" {
                address     = "127.0.0.1:8200"
                tls_disable = 1
              }
              EOF2
              nohup vault server -config=/etc/vault-config/vault.hcl &
              EOF

  tags = {
    Name = "vault-server"
  }
}
