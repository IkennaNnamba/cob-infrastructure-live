# 02: Shared platform networking instead of per-team VPCs

## Decision
Platform Engineering owns one VPC per environment. Teams consume subnet and
security group IDs via terraform_remote_state rather than creating their own VPCs.

## Reasoning
Multiple VPCs per environment would mean managing peering or a Transit
Gateway for any cross-team communication, and would duplicate networking
decisions (CIDR planning, NAT strategy) across every team. A single
platform-owned network per environment keeps routing and IP planning
centralised while still letting teams provision everything else independently.

## Trade-off
Teams have a one-directional dependency on platform's networking leaf being
applied before their own compute/database resources can be created.