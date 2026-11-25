terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}

provider "aws" {
  region              = "ap-southeast-1"
  allowed_account_ids = ["701254204984"]

  default_tags {
    tags = {
      Project   = "minibank"
      ManagedBy = "terraform"
      Stack     = "persistent"
      env       = "dev"
      component = "data"
    }
  }
}
