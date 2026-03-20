provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "region2"
  region = var.backup_region
}
