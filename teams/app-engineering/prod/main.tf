data "terraform_remote_state" "platform_prod" {
  backend = "s3"
  config = {
    bucket = "beejan-cob-terraform-state"
    key    = "platform/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

module "web_server_role" {
  source          = "../../../modules/iam"
  team            = "app-engineering"
  environment     = "prod"
  role_name       = "web-server"
  trusted_service = "ec2.amazonaws.com"

  policy_statements = []
}

module "web_server" {
  source        = "../../../modules/compute-ec2"
  team          = "app-engineering"
  environment   = "prod"
  purpose       = "web-server"
  subnet_id     = data.terraform_remote_state.platform_prod.outputs.private_subnet_ids[0]
  iam_role_name = module.web_server_role.role_name

  ingress_rules = [
    {
      description = "HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "cob_orders_db" {
  source = "../../../modules/relational-database"

  team        = "app-engineering"
  environment = "prod"
  purpose     = "orders"

  engine         = "postgres"
  engine_version = "16.4"

  private_subnet_ids         = data.terraform_remote_state.platform_prod.outputs.private_subnet_ids
  allowed_security_group_ids = [module.web_server.security_group_id]

  multi_az            = true
  skip_final_snapshot = false
  prevent_destroy     = true
}