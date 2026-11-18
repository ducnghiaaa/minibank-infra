locals {
  allowed_region = "ap-southeast-1"

  # must match the Karpenter NodePool in the workload cluster
  allowed_instance_families = ["t4g", "c6g", "c7g", "m6g", "m7g"]
  allowed_instance_sizes    = ["nano", "micro", "small", "medium", "large", "xlarge"]
  allowed_instance_types = [
    for pair in setproduct(local.allowed_instance_families, local.allowed_instance_sizes) :
    "${pair[0]}.${pair[1]}"
  ]

  # global services, or services that only live in us-east-1
  region_exempt_actions = [
    "iam:*",
    "sts:*",
    "organizations:*",
    "account:*",
    "route53:*",
    "route53domains:*",
    "cloudfront:*",
    "acm:*",
    "wafv2:*",
    "budgets:*",
    "ce:*",
    "cur:*",
    "pricing:*",
    "support:*",
    "health:*",
    "s3:ListAllMyBuckets",
    "s3:GetAccountPublic*",
    "s3:PutAccountPublic*",
  ]
}

data "aws_iam_policy_document" "workload_guardrails" {
  statement {
    sid         = "DenyOtherRegions"
    effect      = "Deny"
    not_actions = local.region_exempt_actions
    resources   = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = [local.allowed_region]
    }
  }

  statement {
    sid       = "DenyLargeInstances"
    effect    = "Deny"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringNotEquals"
      variable = "ec2:InstanceType"
      values   = local.allowed_instance_types
    }
  }

  statement {
    sid    = "ProtectCloudTrail"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyLeaveOrganization"
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "workload_guardrails" {
  name        = "workload-guardrails"
  description = "Region, instance size and audit guardrails for workload accounts"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.workload_guardrails.minified_json
}

resource "aws_organizations_policy_attachment" "workload_guardrails" {
  policy_id = aws_organizations_policy.workload_guardrails.id
  target_id = aws_organizations_organizational_unit.workloads.id
}
