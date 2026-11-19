locals {
  repo         = "ducnghiaaa/minibank-infra"
  state_bucket = "minibank-tfstate-701254204984"

  # role name => who may assume it, and what it may do
  roles = {
    tf-plan = {
      subjects   = ["repo:${local.repo}:pull_request", "repo:${local.repo}:ref:refs/heads/main"]
      policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    }
    tf-apply = {
      # only jobs that use the "dev" environment, which needs manual approval
      subjects   = ["repo:${local.repo}:environment:dev"]
      policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "trust" {
  for_each = local.roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value.subjects
    }
  }
}

resource "aws_iam_role" "ci" {
  for_each = local.roles

  name                 = each.key
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "ci" {
  for_each = local.roles

  role       = aws_iam_role.ci[each.key].name
  policy_arn = each.value.policy_arn
}

# ReadOnlyAccess cannot write the state lock file
data "aws_iam_policy_document" "tf_plan_lock" {
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "tf_plan_lock" {
  name   = "state-lock"
  role   = aws_iam_role.ci["tf-plan"].name
  policy = data.aws_iam_policy_document.tf_plan_lock.json
}

output "role_arns" {
  value = { for name, role in aws_iam_role.ci : name => role.arn }
}
