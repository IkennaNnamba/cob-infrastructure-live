variable "github_subject_prefix" {
  description = "Start of the OIDC subject GitHub presents for this repo. It includes the immutable owner and repo IDs."
  type        = string
  default     = "repo:IkennaNnamba@211341729/cob-infrastructure-live@1350867476"
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