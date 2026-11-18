terraform {
  backend "s3" {
    bucket       = "minibank-tfstate-722433231642"
    key          = "bootstrap/management/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
