terraform {
  backend "s3" {
    bucket         = "beejan-cob-terraform-state"
    key            = "app-engineering/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cob-terraform-locks"
    encrypt        = true
  }
}