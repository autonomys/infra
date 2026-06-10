terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      # region2 alias retained transiently so Terraform can destroy
      # orphaned KMS and backup-replication resources in us-west-1.
      # Remove this alias once those orphans are gone from state.
      configuration_aliases = [aws.region2]
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
