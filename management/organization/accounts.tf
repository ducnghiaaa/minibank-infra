data "aws_organizations_organization" "this" {}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "workloads"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "workload" {
  name      = "andrew21-workload"
  email     = var.workload_account_email
  parent_id = aws_organizations_organizational_unit.workloads.id

  lifecycle {
    # destroying this resource would remove the account from the organization
    prevent_destroy = true
    # creation-only settings, AWS never returns them
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
