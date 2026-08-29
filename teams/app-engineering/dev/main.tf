data "terraform_remote_state" "platform_dev" {
  backend = "s3"
  config = {
    bucket = "beejan-cob-terraform-state"
    key    = "platform/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

module "web_server_role" {
  source = "../../../modules/iam"

  team            = "app-engineering"
  environment     = "dev"
  role_name       = "web-server"
  trusted_service = "ec2.amazonaws.com"

  policy_statements = [ ]
}

module "web_server" {
  source = "../../../modules/compute-ec2"

  team        = "app-engineering"
  environment = "dev"
  purpose     = "web-server"
  subnet_id   = data.terraform_remote_state.platform_dev.outputs.private_subnet_ids[0]

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
  environment = "dev"
  purpose     = "orders"

  engine         = "postgres"
  engine_version = "16.4"

  private_subnet_ids         = data.terraform_remote_state.platform_dev.outputs.private_subnet_ids
  allowed_security_group_ids = [module.web_server.security_group_id]
}

