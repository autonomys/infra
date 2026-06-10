provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Retained transiently to let Terraform destroy orphaned KMS + RDS
# backup-replication resources in us-west-1. Once those are gone from
# state, remove this alias, the backup_region variable, and the
# aws.region2 passthrough in main.tf.
provider "aws" {
  alias      = "region2"
  region     = var.backup_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias      = "auth"
  region     = var.auth_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
