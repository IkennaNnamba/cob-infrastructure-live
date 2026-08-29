variable "team" {
  description = "Team this instance belongs to"
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
  description = "Short name for what this instance is for, e.g. web-server, bastion"
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch the instance into"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "assign_public_ip" {
  description = "Give the instance a public IP. Only makes sense for a bastion in a public subnet"
  type        = bool
  default     = false
}

variable "ingress_rules" {
  description = "Inbound rules to open on this instance's security group. Empty by default"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "iam_role_name" {
  description = "Name of an existing IAM role (from the iam module) to attach to this instance. Leave blank for no role"
  type        = string
  default     = ""
}

variable "root_volume_size_gb" {
  description = "Size of the root disk in GB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Extra tags to merge into every resource this module creates"
  type        = map(string)
  default     = {}
}

variable "ami_id" {
  description = "Specific AMI to use. Leave blank to auto-pick the latest Amazon Linux AMI"
  type        = string
  default     = ""
}

variable "attach_iam_role" {
  description = "Whether to attach an IAM role to this instance"
  type        = bool
  default     = false
}