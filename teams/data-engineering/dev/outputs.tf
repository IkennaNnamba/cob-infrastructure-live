output "datalake_bucket_name" {
  value = module.datalake.bucket_name
}

output "datalake_bucket_arn" {
  value = module.datalake.bucket_arn
}

output "catalog_database_name" {
  value = module.datalake_catalog.database_name
}

output "catalog_workgroup_name" {
  value = module.datalake_catalog.workgroup_name
}

output "results_bucket_arn" {
  value = module.datalake_catalog.results_bucket_arn
}

output "environment" {
  value = "dev"
}