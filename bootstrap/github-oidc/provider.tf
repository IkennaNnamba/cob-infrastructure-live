provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "COB"
      ManagedBy = "Terraform"
      Stack     = "bootstrap-github-oidc"
    }
  }
}
