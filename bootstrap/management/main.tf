terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"

  # refuse to run against any other account
  allowed_account_ids = ["722433231642"]

  default_tags {
    tags = {
      Project   = "minibank"
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}

module "state" {
  source = "../../modules/state-bucket"
  name   = "minibank-tfstate-722433231642"
}

output "bucket" {
  value = module.state.bucket
}
