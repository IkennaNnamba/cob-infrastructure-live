data "aws_caller_identity" "current" {}

locals {
  oidc_host  = "token.actions.githubusercontent.com"
  account_id = data.aws_caller_identity.current.account_id

  # The plan role is used by PR runs and by plan jobs on main. Neither runs in an environment.
  plan_subjects = [
    "repo:${var.github_repo}:pull_request",
    "repo:${var.github_repo}:ref:refs/heads/main",
  ]

  # Apply roles trust only jobs that run inside a specific GitHub Environment.
  apply_dev_subjects  = [for l in var.leaves : "repo:${var.github_repo}:environment:${l}-dev"]
  apply_prod_subjects = [for l in var.leaves : "repo:${var.github_repo}:environment:${l}-prod"]

  ci_roles = {
    "cob-gha-plan"       = local.plan_subjects
    "cob-gha-apply-dev"  = local.apply_dev_subjects
    "cob-gha-apply-prod" = local.apply_prod_subjects
  }

  apply_roles = ["cob-gha-apply-dev", "cob-gha-apply-prod"]
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "trust" {
  for_each = local.ci_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "ci" {
  for_each = local.ci_roles

  name                 = each.key
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600
}


resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.ci["cob-gha-plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_lock" {
  statement {
    sid       = "HoldStateLock"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:us-east-1:${local.account_id}:table/${var.lock_table}"]
  }
}

resource "aws_iam_role_policy" "plan_lock" {
  name   = "state-lock"
  role   = aws_iam_role.ci["cob-gha-plan"].id
  policy = data.aws_iam_policy_document.plan_lock.json
}


resource "aws_iam_role_policy_attachment" "apply_poweruser" {
  for_each = toset(local.apply_roles)

  role       = aws_iam_role.ci[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "apply_iam" {
  statement {
    sid       = "ManageWorkloadRoles"
    actions   = ["iam:*Role*", "iam:*InstanceProfile*", "iam:CreateServiceLinkedRole"]
    resources = ["*"]
  }

  statement {
    sid       = "ProtectPipelineRoles"
    effect    = "Deny"
    actions   = ["iam:*Role*"]
    resources = [for name in keys(local.ci_roles) : "arn:aws:iam::${local.account_id}:role/${name}"]
  }
}

resource "aws_iam_role_policy" "apply_iam" {
  for_each = toset(local.apply_roles)

  name   = "workload-iam"
  role   = aws_iam_role.ci[each.key].id
  policy = data.aws_iam_policy_document.apply_iam.json
}
