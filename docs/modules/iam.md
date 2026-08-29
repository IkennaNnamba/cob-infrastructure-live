# IAM Module

Creates a single IAM role scoped to one workload, along with its trust policy
(who can assume it) and an inline permissions policy (what it can do).

Does not create IAM users or groups - see ../decisions/05-iam-module-scoped-to-workload-identity.md

## Required inputs

| Name | Type | Description |
|---|---|---|
| `team` | string | Owning team |
| `environment` | string | `dev`, `staging`, or `prod` |
| `role_name` | string | Short name for what this role is for, e.g. `web-service` |
| `trusted_service` | string | AWS service principal allowed to assume this role, e.g. `ec2.amazonaws.com` |
| `policy_statements` | list(object) | Permissions to grant - see example below |

## Optional inputs

| Name | Default | Description |
|---|---|---|
| `tags` | `{}` | Extra tags merged on top of platform defaults |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | Use when attaching this role to compute, or granting cross-team access to it |
| `role_name` | Use when attaching AWS-managed policies separately |

## Example usage

```hcl
module "task_role" {
  source = "../../../modules/iam"

  team            = "app-engineering"
  environment     = "dev"
  role_name       = "web-service"
  trusted_service = "ecs-tasks.amazonaws.com"

  policy_statements = [
    {
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::some-bucket/*"]
    }
  ]
}
```

## Known limitations

- `policy_statements` with an empty list will fail at `apply`, not `plan` (AWS
  rejects a policy document with zero statements). Not yet caught earlier by
  a variable validation.