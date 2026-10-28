# bootstrap

Stacks that the CI/CD pipeline depends on. They are applied **by hand** by a human from a laptop, never by the pipeline itself: the pipeline's own permissions should not be something the pipeline can change.

| Stack | Purpose |
|---|---|
| `github-oidc/` | GitHub OIDC provider and the IAM roles the workflows assume (`cob-gha-plan`, `cob-gha-apply-dev`, `cob-gha-apply-prod`) |

Apply with `export AWS_PROFILE=<profile>`, then `terraform init`, `terraform plan -out=tfplan`, `terraform apply tfplan`.
