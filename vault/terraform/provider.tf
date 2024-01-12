terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.15.2" # Replace with the desired version of the Vault provider
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

# Provider configuration (adjust as needed)
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "vault" {
  address = "http://localhost:8200" # Replace with the desired Vault address

  s3 {
    bucket     = aws_s3_bucket.vault_storage.id
    region     = var.aws_region # Replace with your desired AWS region
    access_key = aws_iam_user.vault.name
    secret_key = aws_iam_user.vault.secret
    kms_key_id = aws_kms_key.vault.arn
  }
}
