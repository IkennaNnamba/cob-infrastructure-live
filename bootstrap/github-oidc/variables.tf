variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to assume the CI roles. Case-sensitive."
  type        = string
  default     = "IkennaNnamba/cob-infrastructure-live"
}

variable "state_bucket" {
  description = "S3 bucket that holds Terraform state"
  type        = string
  default     = "beejan-cob-terraform-state"
}

variable "lock_table" {
  description = "DynamoDB table used for Terraform state locking"
  type        = string
  default     = "cob-terraform-locks"
}