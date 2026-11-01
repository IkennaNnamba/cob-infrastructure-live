# Using the CI/CD pipeline

## Making a change (the normal path)

1. **Branch from an up-to-date `main`.**
   ```bash
   git checkout main && git pull
   git checkout -b feat/my-change
   ```
2. **Edit the Terraform** in the leaf you want to change, for example `teams/data-engineering/dev/main.tf`.
3. **Commit, push and open a pull request.**
   ```bash
   git add <files>
   git commit -m "Describe the change"
   git push -u origin feat/my-change
   gh pr create --base main --head feat/my-change --title "..." --body "..."
   ```
4. **Read the checks.** `gh pr checks --watch` or the PR page.
   - `Check <leaf>` jobs must be green. A red job shows the exact file, line and reason.
   - `Plan <leaf>` posts a comment with the full plan. **Read it.** Look for the totals line (`Plan: X to add, Y to change, Z to destroy`) and be suspicious of anything being destroyed.
5. **Merge** once checks are green and the plan is what you expect: `gh pr merge <number> --merge --delete-branch`. Merging is refused if a required check is red.
6. **Watch the apply.** The `Terraform Apply` workflow starts on its own.
   - `dev` leaves apply automatically.
   - `prod` leaves stop at **Review deployments**. The named reviewer opens the run in GitHub, checks the plan in the run summary, and approves or rejects.
7. **Check the report.** The `Deployment report` job and the run summary say whether each stage succeeded.

## Re-running without a change

Use the manual trigger to run a leaf on demand, for example to confirm nothing has drifted:

```bash
gh workflow run terraform-apply.yml -f leaf=teams/data-engineering/dev
```

On an unchanged environment the plan says `No changes` and the apply is an empty plan (`0 added, 0 changed, 0 destroyed`).

## Releasing a module change

Module repositories use immutable version tags. A fix is always a new tag, never a moved one.

1. Change the module on a branch in `cob-infrastructure-modules`, open a PR, merge it.
2. Tag the merge commit: `git tag -a v1.0.3 -m "What changed"` then `git push origin v1.0.3`.
3. In `cob-infrastructure-live`, change `?ref=v1.0.2` to the new tag in the leaves that should adopt it, and send that through the normal path above. Each leaf adopts the new version on its own schedule, with a reviewed plan.

## Adding a new leaf

1. Create the folder with `main.tf`, `provider.tf` and `backend.tf` (unique state key).
2. Add the leaf to the matrix in `.github/workflows/terraform-pr.yml`.
3. Add it to the options list in `.github/workflows/terraform-apply.yml`.
4. Add `Check <leaf>` to the required status checks on `main` (branch protection, through the API).

## Rules

- Never commit state files or saved plans (`*.tfstate`, `*.tfplan`, `tfplan`). They are in `.gitignore`.
- Never put AWS keys in the repository or in GitHub. Access is through OIDC only.
- Never edit the `bootstrap/` stacks through the pipeline. They are applied by hand.
- Do not click Save on the branch protection page in the GitHub web UI. Saving that form can overwrite the rule that was set through the API. Check the rule with:
  ```bash
  gh api repos/IkennaNnamba/cob-infrastructure-live/branches/main/protection --jq '{required_checks: .required_status_checks.contexts, strict: .required_status_checks.strict, enforce_admins: .enforce_admins.enabled, force_push_allowed: .allow_force_pushes.enabled}'
  ```

## Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | The role's trust policy does not match the job's identity. Find the subject GitHub actually sent with `aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity` and compare with `github_subject_prefix` in `bootstrap/github-oidc`. |
| A job shows only `exit code 1` | Read the job's real log: `gh api repos/<owner>/<repo>/actions/jobs/<job-id>/logs \| tail -50`. |
| `Check` is green but `Plan` is red | The plan found something validate cannot see, such as a name that is too long for AWS or an unreadable data source. Read the plan job log. |
| PR says it cannot be merged cleanly | Your branch was started from an old commit. Run `git fetch origin && git merge origin/main`, resolve the conflict, push again. |
| Local `terraform` fails on credentials | The login session expired. Run `aws login --profile tf`, then `export AWS_PROFILE=terraform`. |
| `Saved plan is stale` on apply | The state changed after the plan was made. Re-run the workflow to make a fresh plan. |
