module "datalake" {
  source      = "git::https://github.com/IkennaNnamba/cob-infrastructure-modules.git//modules/object-storage?ref=v1.0.2"
  team        = "data-engineering"
  environment = "dev"
  purpose     = "datalake"

# Added for Scenario A pipeline validation test
  tags = {
    TestScenario = "valid-change-v1.0.2"
  }  
}

module "datalake_catalog" {
  source             = "git::https://github.com/IkennaNnamba/cob-infrastructure-modules.git//modules/data-catalog?ref=v1.0.2"
  team               = "data-engineering"
  environment        = "dev"
  purpose            = "datalake"
  source_bucket_name = module.datalake.bucket_name
  source_bucket_arn  = module.datalake.bucket_arn
}

