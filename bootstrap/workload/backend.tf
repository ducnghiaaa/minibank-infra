terraform {
  backend "s3" {
    bucket       = "minibank-tfstate-701254204984"
    key          = "bootstrap/workload/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
