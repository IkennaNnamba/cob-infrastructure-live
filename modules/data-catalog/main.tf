locals {
  name_prefix = "cob-${var.team}-${var.environment}-${var.purpose}"

  common_tags = merge(
    {
      Team        = var.team
      Environment = var.environment
      Platform    = "cob"
    },
    var.tags
  )
}

module "crawler_role" {
  source = "../iam"

  team            = var.team
  environment     = var.environment
  role_name       = "${var.purpose}-crawler"
  trusted_service = "glue.amazonaws.com"

  policy_statements = [
    {
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = [var.source_bucket_arn, "${var.source_bucket_arn}/*"]
    },
    {
      actions = [
        "glue:GetDatabase", "glue:CreateTable", "glue:UpdateTable",
        "glue:GetTable", "glue:GetTables", "glue:BatchCreatePartition"
      ]
      resources = ["*"]
    }
  ]

  tags = var.tags
}

resource "aws_glue_catalog_database" "this" {
  name = replace(local.name_prefix, "-", "_")
}

resource "aws_glue_crawler" "this" {
  name          = "${local.name_prefix}-crawler"
  role          = module.crawler_role.role_arn
  database_name = aws_glue_catalog_database.this.name
  schedule      = var.crawler_schedule != "" ? var.crawler_schedule : null

  s3_target {
    path = "s3://${var.source_bucket_name}/"
  }

  tags = local.common_tags
}

resource "aws_s3_bucket" "athena_results" {
  bucket_prefix = "${local.name_prefix}-results-"
  force_destroy = true

  tags = local.common_tags
}

resource "aws_athena_workgroup" "this" {
  name = "${local.name_prefix}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }

  tags = local.common_tags
}

