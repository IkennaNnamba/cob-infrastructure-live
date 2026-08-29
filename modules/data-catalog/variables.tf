variable "team" {
  description = "Team this catalog belongs to"
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
  description = "Short name for this catalog, e.g. datalake"
  type        = string
}

variable "source_bucket_name" {
  description = "Name of the S3 bucket to crawl, from the object-storage module"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN of the S3 bucket to crawl, from the object-storage module"
  type        = string
}

variable "crawler_schedule" {
  description = "Cron expression for how often the crawler re-scans the bucket, e.g. cron(0 6 * * ? *). Leave blank to only run on demand"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Extra tags to merge into every resource this module creates"
  type        = map(string)
  default     = {}
}