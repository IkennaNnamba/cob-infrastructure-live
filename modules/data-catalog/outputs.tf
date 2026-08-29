output "database_name" {
  value = aws_glue_catalog_database.this.name
}

output "crawler_name" {
  value = aws_glue_crawler.this.name
}

output "workgroup_name" {
  value = aws_athena_workgroup.this.name
}

output "results_bucket_arn" {
  value = aws_s3_bucket.athena_results.arn
}