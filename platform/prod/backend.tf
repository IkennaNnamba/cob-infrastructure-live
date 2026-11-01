terraform {
  backend "s3" {
    bucket         = "beejan-cob-terraform-state"
    key            = "platform/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cob-terraform-locks"
    encrypt        = true
  }
}