terraform {
  backend "s3" {
    bucket       = "minibank-tfstate-701254204984"
    key          = "workload/dev/persistent/ci-oidc/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
