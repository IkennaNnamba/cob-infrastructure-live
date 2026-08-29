variable "team" {
  description = "Team this role belongs to"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "role_name" {
  description = "Short name for what this role is for"
  type        = string
}

variable "trusted_service" {
  description = "AWS service that can assume this role"
  type        = string
}

variable "policy_statements" {
  description = "List of IAM policy statements to attach to this role"
  type = list(object({
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
  }))
}

variable "tags" {
  description = "Extra tags to merge into every resource this module creates"
  type        = map(string)
  default     = {}
}