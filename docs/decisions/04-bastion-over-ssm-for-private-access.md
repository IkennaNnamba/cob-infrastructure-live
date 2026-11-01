# 0004: Bastion host over SSM for private subnet access

## Decision
Teams needing SSH access to private-subnet instances use a bastion host
(a small EC2 instance in a public subnet) rather than AWS Systems Manager
Session Manager with VPC interface endpoints.

## Reasoning
SSM + VPC endpoints removes the need for any public-facing instance at all,
but adds interface endpoint resources and cost per endpoint per AZ. A bastion
is a more familiar, simpler pattern for this project's scope and timeline.

## Trade-off
Bastion is one more instance to patch and manage, and is a (small) internet-facing
attack surface. SSM would be the better long-term choice for a real production
platform - noted here as a future improvement, not implemented in this version.