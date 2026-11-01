# 05: IAM module scoped to workload identity only

## Decision
The IAM module creates roles for AWS services to assume (EC2, ECS, etc.) only.
It does not create IAM users or groups.

## Reasoning
IAM users rely on long-lived access keys, which is what AWS itself steers
teams away from for anything programmatic - leaked static credentials are
one of the most common real-world AWS security incidents. Roles hand out
temporary credentials via sts:AssumeRole instead, which expire automatically.

Human login access is handled separately through AWS SSO / IAM Identity
Center (already in use for this project), not through Terraform-managed
IAM users. Groups exist to organize users, so with no users being created
here, there's nothing for a group to group.

## Trade-off
If a future requirement genuinely needs a Terraform-managed IAM user, this module
would need to be extended or a separate one written. Not needed for COB's
current scope.
