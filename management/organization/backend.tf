terraform {
  backend "s3" {
    bucket       = "minibank-tfstate-722433231642"
    key          = "management/organization/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
