module "networking" {
  source = "git::https://github.com/IkennaNnamba/cob-infrastructure-modules.git//modules/networking?ref=v1.0.0"

  team        = "platform"
  environment = "dev"

  vpc_cidr = "10.58.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.58.0.0/20", "10.58.16.0/20"]
  private_subnet_cidrs = ["10.58.32.0/20", "10.58.48.0/20"]

  enable_nat_gateway = true
  single_nat_gateway = true
}
locals {
  test = "x"
}
