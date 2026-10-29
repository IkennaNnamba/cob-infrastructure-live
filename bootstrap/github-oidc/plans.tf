# Everything about storing saved plan files lives in this file.

# ---- private bucket for saved plan files (deleted after 1 day) ----

resource "aws_s3_bucket" "plans" {
  bucket = "beejan-cob-terraform-plans-${local.account_id}"
}

resource "aws_s3_bucket_public_access_block" "plans" {
  bucket                  = aws_s3_bucket.plans.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "plans" {
  bucket = aws_s3_bucket.plans.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "plans" {
  bucket = aws_s3_bucket.plans.id

  rule {
    id     = "delete-old-plans"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }
  }
}

# ---- extra permissions for the plan role ----

data "aws_iam_policy_document" "plan_extra" {
  statement {
    sid       = "SavePlanFiles"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.plans.arn}/*"]
  }

  statement {
    sid       = "ReadDbSecretsForRefresh"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:us-east-1:${local.account_id}:secret:cob-*-db-credentials-*"]
  }
}

resource "aws_iam_role_policy" "plan_extra" {
  name   = "plan-extras"
  role   = aws_iam_role.ci["cob-gha-plan"].id
  policy = data.aws_iam_policy_document.plan_extra.json
}

output "plans_bucket" {
  description = "Private bucket where the pipeline keeps saved plan files"
  value       = aws_s3_bucket.plans.bucket
}