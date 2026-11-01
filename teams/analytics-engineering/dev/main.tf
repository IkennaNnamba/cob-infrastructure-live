data "terraform_remote_state" "data_engineering_dev" {
  backend = "s3"
  config = {
    bucket = "beejan-cob-terraform-state"
    key    = "data-engineering/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

module "analyst_query_role" {
  source          = "git::https://github.com/IkennaNnamba/cob-infrastructure-modules.git//modules/iam?ref=v1.0.0"
  team            = "analytics-engineering"
  environment     = "dev"
  role_name       = "athena-query-access"
  trusted_service = "ec2.amazonaws.com"

  policy_statements = [
    {
      actions   = ["glue:GetDatabase", "glue:GetTable", "glue:GetTables", "glue:GetPartitions"]
      resources = ["*"]
    },
    {
      actions   = ["s3:GetObject"]
      resources = ["${data.terraform_remote_state.data_engineering_dev.outputs.datalake_bucket_arn}/*"]
    },
    {
      actions   = ["s3:GetObject", "s3:PutObject"]
      resources = ["${data.terraform_remote_state.data_engineering_dev.outputs.results_bucket_arn}/*"]
    }
  ]
}