# 01: Directory isolation over Terraform workspaces

## Decision
COB uses separate directories with their own state files for isolation
(team/environment/component), rather than Terraform workspaces.

## Reasoning
Workspaces share the same backend configuration and state namespace,
differing only by a suffix - a wrong `terraform workspace select` is an easy,
low-visibility mistake with high blast radius. Workspaces also don't support
per-workspace IAM permissions cleanly, since permissions are granted per
state file path. Directory isolation makes the wrong-environment mistake
much harder to make (wrong `cd`, not wrong flag) and allows real per-team,
per-environment AWS permission boundaries on state access.

## Trade-off
More repeated backend/provider boilerplate per leaf directory, accepted in
exchange for stronger isolation.