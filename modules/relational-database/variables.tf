variable "team" {
  description = "Team this database belongs to"
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
  description = "Short name for what this database is for, e.g. orders, users"
  type        = string
}

variable "private_subnet_ids" {
  description = "At least two private subnets, in different AZs, for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to this database, e.g. a compute module's SG"
  type        = list(string)
}

variable "engine" {
  description = "Database engine, e.g. postgres, mysql"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version, e.g. 16.4"
  type        = string
}

variable "instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage_gb" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Run a standby replica in a second AZ. Prod-only in practice, but the platform doesn't block dev from using it"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "How many days of automatic backups to keep"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip taking a final snapshot on delete. Should be false in prod"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags to merge into every resource this module creates"
  type        = map(string)
  default     = {}
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "db_port" {
  description = "Port the database listens on. Leave blank to use the standard port for the chosen engine"
  type        = number
  default     = null
}

variable "prevent_destroy" {
  description = "Block this database from being destroyed by Terraform. Recommended true for prod"
  type        = bool
  default     = false
}