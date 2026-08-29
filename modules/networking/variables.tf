variable "team" {
  description = "Team this network belongs to, e.g. platform, data-engineering"
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ. Must fall inside vpc_cidr."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ. Must fall inside vpc_cidr."
  type        = list(string)
} 

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnet egress. Usually off in dev to save cost."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per AZ. Only respected in prod - dev is always forced to single."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags to merge into every resource this module creates"
  type        = map(string)
  default     = {}
}