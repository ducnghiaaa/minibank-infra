locals {
  services = ["security", "account", "notification"]

  lifecycle_policy = jsonencode({
    rules = [
      {
        # attestations left behind by failed pushes; images an index still points to are kept
        rulePriority = 1
        description  = "expire untagged after 1 day"
        selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 1 }
        action       = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "keep the 20 newest images"
        selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 20 }
        action       = { type = "expire" }
      },
    ]
  })
}

resource "aws_ecr_repository" "this" {
  for_each = toset(local.services)

  name = "minibank/${each.key}"

  # tag = git SHA; one tag, one image, forever
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name
  policy     = local.lifecycle_policy
}
