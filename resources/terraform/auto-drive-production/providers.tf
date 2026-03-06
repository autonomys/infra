provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "region2"
  region = "us-west-1"
}
