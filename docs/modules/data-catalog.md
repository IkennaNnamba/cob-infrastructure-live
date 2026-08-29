# Data Catalog Module

Sets up a Glue crawler and catalog database over an existing S3 bucket, plus
an Athena workgroup for querying it. Creates its own crawler IAM role
internally (via the iam module) since a crawler's permissions are always
the same shape - it doesn't ask the caller to build one.

## Required inputs

| Name | Type | Description |
|---|---|---|
| `team` | string | Owning team |
| `environment` | string | `dev`, `staging`, or `prod` |
| `purpose` | string | Short name for this catalog, e.g. `datalake` |
| `source_bucket_name` | string | Bucket to crawl, from the object-storage module |
| `source_bucket_arn` | string | Same bucket's ARN, from the object-storage module |

## Optional inputs

| Name | Default | Description |
|---|---|---|
| `crawler_schedule` | `""` (on-demand only) | Cron expression for automatic re-crawls, e.g. `cron(0 6 * * ? *)` |
| `tags` | `{}` | Extra tags merged on top of platform defaults |

## Outputs

| Name | Description |
|---|---|
| `database_name` | Reference this catalog by name in queries or IAM policies |
| `crawler_name` | Trigger a manual crawl (`aws glue start-crawler`) instead of waiting for a schedule |
| `workgroup_name` | Needed when running Athena queries |
| `results_bucket_arn` | Grant a querying team's own IAM role read/write access to query results here |

## Example usage

```hcl
module "datalake_catalog" {
  source = "../../../modules/data-catalog"

  team               = "data-engineering"
  environment        = "dev"
  purpose            = "datalake"
  source_bucket_name = module.datalake.bucket_name
  source_bucket_arn  = module.datalake.bucket_arn
}
```

## Assumptions

- This module only provisions the catalog and crawler - it does not grant
  any human or application permission to actually *query* the data. Whichever
  team needs to run Athena queries builds their own role via the iam module,
  granting themselves `glue:Get*` on the catalog, `s3:GetObject` on the source
  bucket, and read/write on `results_bucket_arn`.

## Security notes

- The crawler's Glue-related IAM permissions use a `"*"` resource, not a
  specific ARN - several Glue catalog API actions don't support
  resource-level restriction, this isn't a shortcut we chose.
- The Athena results bucket (`aws_s3_bucket.athena_results`) is created as a
  plain bucket, not through the object-storage module - it has no
  encryption, versioning, or public access block. Treated as disposable
  scratch space for query output, not a place real data lives.

## Known limitations

- No built-in way to grant query access to other teams - entirely left to
  the querying team's own IAM setup, by design (see Assumptions).
- The Athena results bucket's lighter security posture (see above) is a
  known inconsistency with the rest of the platform's storage standards.