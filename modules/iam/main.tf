locals {
  name_prefix = "cob-${var.team}-${var.environment}-${var.role_name}"

  common_tags = merge(
    {
      Team        = var.team
      Environment = var.environment
      Platform    = "cob"
    },
    var.tags
  )
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.trusted_service]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "${local.name_prefix}-"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "permissions" {
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "this" {
  name_prefix = "${local.name_prefix}-"
  role        = aws_iam_role.this.id
  policy      = data.aws_iam_policy_document.permissions.json
}

