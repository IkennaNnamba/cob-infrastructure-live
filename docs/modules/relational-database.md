# Relational Database Module

Creates an RDS instance with its own subnet group, a security group that only
accepts traffic from explicitly approved security groups, and auto-generated
credentials stored in Secrets Manager - never passed in as plaintext.

## Required inputs

| Name | Type | Description |
|---|---|---|
| `team` | string | Owning team |
| `environment` | string | `dev`, `staging`, or `prod` |
| `purpose` | string | Short name for the database, e.g. `orders`, `users` |
| `private_subnet_ids` | list(string) | At least two private subnets, in different AZs (RDS requirement) |
| `allowed_security_group_ids` | list(string) | Security groups allowed to connect, e.g. a compute module's SG - see Assumptions |
| `engine_version` | string | Engine version, e.g. `16.4` |

## Optional inputs

| Name | Default | Description |
|---|---|---|
| `engine` | `postgres` | Database engine |
| `db_username` | `dbadmin` | Master username |
| `db_port` | auto (5432/3306 by engine) | Override if you need a non-standard port or an engine this module doesn't guess correctly for |
| `instance_class` | `db.t3.micro` | RDS instance size |
| `allocated_storage_gb` | `20` | Storage size in GB |
| `multi_az` | `false` | Run a standby replica in a second AZ. Not enforced prod-only - team's decision |
| `backup_retention_days` | `7` | Days of automatic backups to keep |
| `skip_final_snapshot` | `true` | Skip a final snapshot on delete. Recommend `false` for prod |
| `prevent_destroy` | `false` | Block Terraform from destroying this database at all. Recommend `true` for prod |
| `tags` | `{}` | Extra tags merged on top of platform defaults |

There's no `db_password` input - a random password is generated automatically
and stored in Secrets Manager. Nobody running Terraform ever sees or types it.

## Outputs

| Name | Description |
|---|---|
| `db_endpoint` | Hostname:port applications connect to |
| `db_port` | The resolved port, on its own |
| `secret_arn` | ARN of the Secrets Manager secret holding credentials - grant an app's IAM role `secretsmanager:GetSecretValue` on this to let it fetch its own DB credentials |
| `security_group_id` | This database's own SG, if something else needs to reference it |

## Example usage

```hcl
module "orders_db" {
  source = "../../../modules/relational-database"

  team           = "app-engineering"
  environment    = "dev"
  purpose        = "orders"
  engine_version = "16.4"

  private_subnet_ids         = data.terraform_remote_state.platform_dev.outputs.private_subnet_ids
  allowed_security_group_ids = [module.web_server.security_group_id]
}
```

## Security notes

- Credentials live only in Secrets Manager. DB admins retrieve them there
  directly, via their own IAM group permissions - not through Terraform.
- Access is controlled by security group membership, not IP ranges or
  subnets - only instances carrying an SG in `allowed_security_group_ids`
  can reach the database at all, regardless of network location.
- Storage is always encrypted, not optional.

## Assumptions

- This database sits in a private subnet with no direct public reachability.
  Human access (e.g. pgAdmin) is expected via a bastion host, not a direct
  internet connection.
- Security group rules only need to be configured on the RDS side. The
  connecting instance's default wide-open egress already permits outbound
  traffic to the database - security groups are stateful, so return traffic
  is automatically allowed without a matching inbound rule on the caller's side.

## Known limitations

- `db_port`'s auto-guess only correctly covers `postgres` (5432) and treats
  anything else as MySQL (3306) - override `db_port` explicitly for other engines.
- `prevent_destroy` accepts a variable value rather than a hardcoded literal,
  which Terraform has historically restricted for lifecycle arguments. Not
  yet confirmed working against a real apply - see backlog.