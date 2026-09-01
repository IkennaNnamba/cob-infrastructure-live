module "datalake" {
  source      = "../../../modules/object-storage"
  team        = "data-engineering"
  environment = "prod"
  purpose     = "datalake"
}

module "datalake_catalog" {
  source              = "../../../modules/data-catalog"
  team                = "data-engineering"
  environment         = "prod"
  purpose             = "datalake"
  source_bucket_name  = module.datalake.bucket_name
  source_bucket_arn   = module.datalake.bucket_arn
}