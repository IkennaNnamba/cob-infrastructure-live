# Engineering decisions, trade-offs and lessons learned

## Decisions

### 1. Two repositories: platform modules and live deployments
- **Decision:** `cob-infrastructure-modules` holds reusable modules; `cob-infrastructure-live` holds deployments and the pipeline. Leaves consume modules through pinned git tags.
- **Why:** This is the platform/customer split the brief asks for. Platform changes are released deliberately, and each consumer upgrades on its own schedule with a reviewed plan.
- **Trade-off:** Two repos to manage, and a module fix needs a release plus a version bump before it reaches a deployment.

### 2. One live repository for all teams
- **Decision:** Platform and all teams share one live repo, with one folder and one state file per team per environment.
- **Why:** One pipeline to maintain and one place to review. State isolation comes from separate state files, not separate repos.
- **Trade-off:** Anyone with write access to the repo can change any team's folder. CODEOWNERS and required reviews would narrow that.

### 3. Pin modules to immutable tags
- **Decision:** `?ref=v1.0.2`, never a branch.
- **Why:** The same commit always produces the same plan. Tags are never moved, so a fix is a new patch version.

### 4. No stored AWS keys: GitHub OIDC with one role per purpose
- **Decision:** Jobs get short-lived credentials by presenting a signed token. Three roles: plan (read-only), apply-dev, apply-prod. Trust policies match the job's identity (pull request or `main` for plan, the environment for apply).
- **Why:** There is no long-lived secret to leak. A pull request can never assume an apply role.
- **Trade-off:** More setup, and the trust policy must match GitHub's exact subject format (see lessons).

### 5. Plan with a read-only role, apply with a separate role
- **Decision:** Anything that runs on a pull request can only read. Writing needs an environment, and environments are limited to `main`.
- **Why:** The riskiest code path, running unreviewed PR code, gets the weakest permissions.

### 6. Apply the saved plan, not a new one
- **Decision:** The plan is saved to a private S3 bucket under the commit SHA, and the apply job downloads and applies exactly that file.
- **Why:** What was reviewed is what runs. If the state moved in between, Terraform rejects the stale plan.
- **Trade-off:** A saved plan can contain secrets from state. The bucket is private, encrypted, blocks public access, and deletes objects after one day. Plan comments use Terraform's readable text, which hides sensitive values.

### 7. Approval gate through GitHub environments
- **Decision:** `dev` applies automatically; `prod` requires a named reviewer. Administrators cannot bypass the prod gate.
- **Why:** Satisfies "do not automatically apply every plan". Cheap environments move fast, production waits for a human.
- **Trade-off:** With a single collaborator, the same person opens and approves. Adding a second reviewer and turning on "prevent self-review" fixes this.

### 8. Branch protection through the API
- **Decision:** Required status checks (all 8 `Check` jobs), up-to-date branch, rules apply to administrators, no force pushes or deletions.
- **Why:** A change cannot merge just because the code looks right.
- **Trade-off:** The `Plan` job is not yet a required check, and a pull request review is not required. See the backlog.

### 9. Bootstrap stacks are applied by hand
- **Decision:** The OIDC provider, roles and plans bucket are not managed by the pipeline.
- **Why:** A pipeline that can change its own permissions can escalate itself. The apply roles also have an explicit deny on modifying the three CI roles.

### 10. Concurrency per leaf
- **Decision:** One run per leaf at a time, queued rather than cancelled.
- **Why:** Prevents two deployments fighting over one state lock. A DynamoDB lock is the second line of defence.

## Gaps found in COB while consuming it (Part A)

| Gap | Belongs in | Status |
|---|---|---|
| Name prefixes overflowed AWS length limits for long team and purpose names (S3 prefix max 37, IAM role prefix max 38) | Platform | **Fixed** in module `v1.0.2` by truncating the prefix; AWS adds a unique suffix |
| Athena results bucket has no public access block, versioning or encryption resources, unlike the data lake bucket | Platform | Open (backlog) |
| Glue crawler IAM policy uses `*` as the resource | Platform | Open (backlog), should be scoped to the lake bucket and database |
| No scheduled crawler or ingestion path | Consumer, until a second team needs it | Open |

## Lessons learned

1. **`validate` is not enough, `plan` is the real test.** The name-length error passed `validate` and was caught only by `plan`, because the final name is only known once the values are combined. This is why the pipeline plans every changed leaf on the pull request.
2. **Check what GitHub actually sends.** The first OIDC test failed because GitHub now puts immutable numeric owner and repo IDs in the token subject. The answer was in CloudTrail, which records the exact subject. The IDs also protect against someone re-creating a deleted repository name.
3. **A UI form can silently undo a rule set by API.** Saving the branch protection page replaced our rule with a blank one. We now verify the rule by reading it back from the API.
4. **Branch from the right commit.** A branch started from the old copy of a file conflicted with the merged version. Always branch from an updated `main`.
5. **Tags are forever.** A broken release is fixed by `v1.0.2`, never by moving `v1.0.1`.
6. **Secrets live in state.** A generated database password is stored in state, so saved plans must be treated as sensitive. The module never outputs the password and stores it in Secrets Manager.
7. **Make failures loud and stages dependent.** Apply jobs only start if the plan succeeded, prod waits for dev, and a final report job turns the whole run red on any failure.

## Known limitations

- Anyone with write access to the live repository can change workflow code, which runs under the plan role. That role can read state and secrets. Mitigations to add: CODEOWNERS on `.github/`, required reviews, and restricting who can push.
- Apply roles use PowerUserAccess plus scoped IAM. This is broad. A least-privilege policy per team is in the backlog.
- GitHub free plan: the repository is public because required reviewers and branch protection need a public repo or a paid plan.

## Backlog

- Make the `Plan` job a required check.
- Require one approving PR review and enable "prevent self-review" on `prod`.
- Add CODEOWNERS for `.github/`, `bootstrap/` and `modules`.
- Pin third-party actions to commit SHAs; move to action versions that run on the current Node runtime.
- Migrate state locking from DynamoDB to S3-native locking.
- Add `tflint` and a policy scanner such as Checkov to the pull request workflow.
- Update the plan comment in place instead of posting a new one on every push.
- Scope the apply roles to least privilege per team.
- Fix the open COB gaps above and release `v1.1.0`.

## Evidence index

| Scenario | Evidence |
|---|---|
| A. Valid change | PR #12 (plan comments, 11 to add), apply run with the `prod` approval, AWS CLI listing of buckets, Glue databases and workgroups |
| B. Invalid Terraform | PR #13, failed `Validate` step (`Unsupported attribute`), merge blocked |
| C. Repeatability | Manual run on `data-engineering/dev`: `No changes`, `0 added, 0 changed, 0 destroyed` |
