module "networking" {
  source = "git::https://github.com/IkennaNnamba/cob-infrastructure-modules.git//modules/networking?ref=v1.0.0"

  team        = "platform"
  environment = "prod"

  vpc_cidr = "10.56.0.0/16"
  azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs  = ["10.56.0.0/20", "10.56.16.0/20", "10.56.32.0/20"]
  private_subnet_cidrs = ["10.56.48.0/20", "10.56.64.0/20", "10.56.80.0/20"]

  enable_nat_gateway = true
  single_nat_gateway = false
}