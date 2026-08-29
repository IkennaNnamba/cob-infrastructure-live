# Compute (EC2) Module

Creates a single EC2 instance with its own security group, encrypted root
volume, and an optional IAM instance profile - not a bare wrapper around
`aws_instance`.

Handles AMI selection and instance profile creation itself so a team only
needs to decide the things that are genuinely specific to their workload.

## Required inputs

| Name | Type | Description |
|---|---|---|
| `team` | string | Owning team |
| `environment` | string | `dev`, `staging`, or `prod` |
| `purpose` | string | Short name for the instance, e.g. `web-server`, `bastion` |
| `subnet_id` | string | Subnet to launch into. Public or private is entirely the caller's choice - see Assumptions below |

## Optional inputs

| Name | Default | Description |
|---|---|---|
| `instance_type` | `t3.micro` | EC2 instance size |
| `ami_id` | `""` (auto) | Specific AMI to use. Leave blank to auto-pick the latest Amazon Linux AMI |
| `assign_public_ip` | `false` | Give the instance a public IP - only makes sense for a bastion in a public subnet |
| `ingress_rules` | `[]` | Inbound rules to open. Empty by default - nothing gets in unless asked for |
| `iam_role_name` | `""` | Name of an existing role from the iam module to attach. Leave blank for no role |
| `root_volume_size_gb` | `20` | Root disk size in GB |
| `tags` | `{}` | Extra tags merged on top of platform defaults |

## Outputs

| Name | Description |
|---|---|
| `instance_id` | Reference this instance elsewhere (load balancer targets, alarms) |
| `private_ip` | Reach this instance from elsewhere in the VPC |
| `public_ip` | Only populated if `assign_public_ip = true` |
| `security_group_id` | Pass into the relational-database module to allow this instance to reach a DB |

## Example usage

**A private app server, using a role from the iam module:**

```hcl
module "task_role" {
  source          = "../../../modules/iam"
  team            = "app-engineering"
  environment     = "dev"
  role_name       = "web-service"
  trusted_service = "ec2.amazonaws.com"
  policy_statements = [
    { actions = ["s3:GetObject"], resources = ["arn:aws:s3:::some-bucket/*"] }
  ]
}

module "web_server" {
  source        = "../../../modules/compute-ec2"
  team          = "app-engineering"
  environment   = "dev"
  purpose       = "web-server"
  subnet_id     = data.terraform_remote_state.platform_dev.outputs.private_subnet_ids[0]
  iam_role_name = module.task_role.role_name
}
```

**A bastion host, in a public subnet, allowing SSH from anywhere (tighten `cidr_blocks` in practice):**

```hcl
module "bastion" {
  source           = "../../../modules/compute-ec2"
  team             = "app-engineering"
  environment      = "dev"
  purpose          = "bastion"
  subnet_id        = data.terraform_remote_state.platform_dev.outputs.public_subnet_ids[0]
  assign_public_ip = true

  ingress_rules = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

## Assumptions

- This module doesn't decide public vs. private subnet placement - the caller
  does, entirely, based on `subnet_id`.
- An instance placed in a private subnet only has internet egress if the
  owning platform environment was built with `enable_nat_gateway = true`.
  This module has no way to grant NAT access on its own - that's a
  platform-level networking decision, not a compute-level one.

## Known limitations

- AMI auto-selection relies on a name pattern (`al2023-ami-*-x86_64`) that
  could change if AWS alters its naming convention. Pin `ami_id` explicitly
  for anything where that risk isn't acceptable.