variable "team" {
  description = "Team this bucket belongs to"
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

variable "purpose" {
  description = "Short name for what this bucket is for, e.g. datalake, app-uploads"
  type        = string
}

variable "versioning_enabled" {
  description = "Keep previous versions of objects on overwrite/delete"
  type        = bool
  default     = true
}

variable "old_version_expiry_days" {
  description = "How long to keep old object versions before deleting them. 0 disables cleanup."
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Allow bucket deletion even if it still has objects in it. Should stay false in prod."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags to merge into every resource this module creates"
  type        = map(string)
  default     = {}
}