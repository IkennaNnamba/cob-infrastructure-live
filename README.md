# COB - Beejan Technologies Infrastructure Platform

Internal Terraform platform for provisioning standardised AWS infrastructure
across engineering teams.

## Start here

- [`docs/architecture.md`](docs/architecture.md) - what COB is, the problem it
  solves, capabilities, and the architecture diagram
- [`docs/modules/`](docs/modules/) - usage docs for each reusable module
  (required inputs, outputs, example usage)
- [`docs/decisions/`](docs/decisions/) - why things were built the way they
  were (ADRs), plus a running backlog of known gaps

## Repository layout

```
modules/    - reusable Terraform modules (owned by Platform Engineering)
platform/   - shared networking, one leaf per environment
teams/      - each team's own infrastructure, one leaf per team per environment
examples/   - a worked example showing how a team composes modules together
docs/       - everything above
```

## Prerequisites

- Terraform >= 1.6.0
- AWS credentials configured (any leaf's `provider.tf` expects a working
  default credential chain)
- The state backend bucket and DynamoDB lock table already exist -
  see `docs/decisions/` for how they were bootstrapped

## Running a leaf

```bash
cd teams/<team>/<environment>
terraform init
terraform plan
```