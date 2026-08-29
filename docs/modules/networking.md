# Networking Module

Provisions a VPC with public/private subnets, routing, optional NAT gateways, and a baseline security group.

## Required inputs

| Name | Type | Description |
|---|---|---|
| `team` | string | Owning team, e.g. `platform`, `app-engineering` |
| `environment` | string | `dev`, `staging`, or `prod` |
| `azs` | list(string) | AZs to spread subnets across |
| `public_subnet_cidrs` | list(string) | One CIDR per AZ, must match `azs` length |
| `private_subnet_cidrs` | list(string) | One CIDR per AZ, must match `azs` length |

## Optional inputs

| Name | Default | Description |
|---|---|---|
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `enable_nat_gateway` | `false` | Enable private subnet internet egress |
| `single_nat_gateway` | `true` | One NAT vs one-per-AZ. **Prod-only setting** — dev is always forced to single regardless of this value |
| `tags` | `{}` | Extra tags merged on top of platform defaults |

## Example usage

```hcl
module "networking" {
  source = "../../../modules/networking"

  team        = "platform"
  environment = "dev"
  vpc_cidr    = "10.58.0.0/16"
  azs         = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.58.0.0/20", "10.58.16.0/20"]
  private_subnet_cidrs = ["10.58.32.0/20", "10.58.48.0/20"]

  enable_nat_gateway = true
}
```