# 03: NAT gateway redundancy enforced prod-only

## Decision
The networking module allows a caller to request multi-AZ NAT gateway
redundancy (`single_nat_gateway = false`), but only honours that request
when `environment = "prod"`. Non-prod environments are always forced to a
single NAT gateway regardless of what's passed in.

## Reasoning
A NAT gateway costs money per hour it exists, multiplied by however many are
created. Multi-AZ redundancy is a legitimate prod concern (avoiding a single
point of failure for egress), but has little justification in dev/staging,
where the cost isn't worth the redundancy. Enforcing this in the module
itself - not just documenting it - means the platform encodes the standard
rather than relying on every team remembering it.

## Trade-off
A team can't test true multi-NAT failover behavior outside of prod using
this module as-is.