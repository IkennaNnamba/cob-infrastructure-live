# 0006: One state file per team per environment, not per component

## Decision
Leaf directories (where Terraform state lives) are organized as one per
team per environment, calling multiple modules where a team needs more
than one capability - rather than a separate leaf and state file per
individual component.

## Reasoning
Per-component state files give the smallest possible blast radius and the
finest-grained locking, but at this project's scale (3 teams x 2 environments)
that granularity added 13 state files and a matching number of backend/provider
boilerplate sets for limited real benefit. Consolidating to 8 state files
(one per team+environment) keeps genuine isolation where it matters most -
between teams, and between dev and prod - while reducing operational overhead.

## Trade-off
A single bad apply within one team's environment can now affect multiple
components at once (e.g. compute and rds-database in the same apply), and
state locking is coarser - unrelated changes within the same team+environment
can't run concurrently. Acceptable for this project's scale; a growing team
could split back out to per-component state later without changing any module.