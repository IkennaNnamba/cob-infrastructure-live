# Object Storage Module

Creates an S3 bucket with versioning, encryption, a hard block on all public
access, and automatic cleanup of old object versions.

Not a thin wrapper around `aws_s3_bucket` - see the module's `main.tf` for the
full set of resources this wires together (versioning, encryption, public
access block, lifecycle) so a team doesn't have to configure each one by hand.

## Required inputs

| Name | Type | Description |
|---|---|---|
| `team` | string | Owning team |
| `environment` | string | `dev`, `staging`, or `prod` |
| `purpose` | string | Short name for what the bucket is for, e.g. `datalake`, `app-uploads` |

## Optional inputs

| Name | Default | Description |
|---|---|---|
| `versioning_enabled` | `true` | Keep old versions of objects on overwrite/delete |
| `old_version_expiry_days` | `90` | How long to keep old object versions before deleting them. `0` disables cleanup |
| `force_destroy` | `false` | Allow deleting the bucket even if it still has objects in it. Leave `false` in prod |
| `tags` | `{}` | Extra tags merged on top of platform defaults |

There's no `bucket_name` input - the module builds a globally unique name from
`team`, `environment`, `purpose`, and your AWS account ID.

Public access is always fully blocked, on every bucket this module creates -
not something a team can opt out of.

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Use when referencing the bucket by name, e.g. in a Glue crawler |
| `bucket_arn` | Use in IAM policy `Resource` fields, including cross-team grants via remote state |

## Example usage

```hcl
module "datalake" {
  source = "../../../modules/object-storage"

  team        = "data-engineering"
  environment = "dev"
  purpose     = "datalake"
}
```

## Security notes

- Encryption uses AWS's default managed KMS key (`aws/s3`), not a customer-managed
  key
- All four public access block settings are hardcoded on, unconditionally.

## Known limitations

- No option for a customer-managed KMS key, so no way to restrict decrypt
  access more tightly than general S3 read permissions.