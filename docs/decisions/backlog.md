# Backlog / known gaps and future improvements

Running list of deliberate scoping decisions and known limitations, kept
here so they read as intentional trade-offs rather than oversights.

## Modules

- `modules/iam`'s `policy_statements` has no minimum-length validation - an
  empty list produces an IAM policy with no `Statement` key, which is valid
  Terraform but invalid IAM and will fail at `apply`, not `plan`. Confirmed
  live in `app-engineering/dev`'s web server role - see
  `examples/app-engineering-web-service/README.md`.
- `modules/relational-database`'s `db_port` auto-guess only correctly covers
  `postgres` (5432) and treats anything else as MySQL (3306). Override
  `db_port` explicitly for other engines.
- `modules/relational-database`'s `prevent_destroy` is implemented as two
  near-identical `aws_db_instance` resources gated by `count`, not a direct
  variable reference, because Terraform's `lifecycle` block requires a
  literal value - confirmed by a real `plan` error during testing.
- `modules/compute-ec2`'s AMI auto-selection relies on a name pattern
  (`al2023-ami-*-x86_64`) that could silently stop matching if AWS changes
  its naming convention. Pin `ami_id` explicitly where that risk matters.
- `modules/compute-ecs` has no ALB/target group integration yet - it runs
  the service but doesn't attach it to a load balancer.
- `modules/data-catalog`'s Athena results bucket is a raw `aws_s3_bucket`,
  not built through `modules/object-storage` - no encryption, versioning, or
  public access block. Treated as disposable query-output scratch space, not
  a place real data lives. A real inconsistency with the rest of the
  platform's storage standards, accepted deliberately for this bucket's use case.
- `modules/data-catalog`'s crawler IAM permissions use a `"*"` resource for
  Glue catalog actions - several Glue API actions don't support
  resource-level restriction, this isn't a shortcut we chose.
- `private_subnet_ids` / `public_subnet_ids` outputs (from `platform/*`) are
  plain ordered lists, not keyed by AZ name. A consuming team has to know or
  check which index corresponds to which AZ.

## Analytics / data catalog access flow

- `analytics-engineering`'s `analyst_query_role` is created but nothing in
  Terraform actually assumes or uses it - no EC2/Lambda attached, and no
  wiring for a human analyst to `sts:AssumeRole` into it. The role is
  correctly scoped but has no consumer yet. Closing this requires either
  granting specific IAM/SSO identities assume-role permission (likely
  managed outside Terraform) or adding a compute component for analysts.
- The Glue crawler is on-demand only by default (`crawler_schedule = ""`) -
  nothing currently triggers it automatically after the datalake bucket
  receives new data. A team must run `aws glue start-crawler` manually, or
  set `crawler_schedule` to a cron expression.


## Testing

- `app-engineering/dev` has been verified with `terraform init`/`plan` only
  (11 resources, 0 errors) - no live `apply`/`destroy` cycle performed yet,
  unlike `platform/dev` which was fully applied and destroyed live. Requires
  `platform/dev` to be live simultaneously and real RDS provisioning time.
- No automated tests (Terratest, `.tftest.hcl`, policy-as-code scanning) -
  `terraform fmt`/`validate` and manual `plan` review only, given project
  scope and timeline.

## Security (deferred by original design)

- No team-level AWS permission boundaries yet controlling who can `terraform
  apply` what - see the original brief's Multi-Layered Security section
  (CODEOWNERS, per-team S3 state bucket IAM policies). Explicitly
  deprioritized until the rest of the platform was built.

## Infrastructure choices

- Backend state locking uses `dynamodb_table`, which the AWS provider flags
  as deprecated in favor of `use_lockfile` (S3-native locking, requires
  Terraform >= 1.10). Left as-is since it's fully functional - migrating
  would mean removing the DynamoDB table and bumping the version constraint
  across every leaf.