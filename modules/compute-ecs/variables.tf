variable "team" {
  description = "Team this service belongs to"
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
  description = "Short name for this service, e.g. orders-api, notifications"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to run the service in, usually private ones"
  type        = list(string)
}

variable "container_image" {
  description = "Full image URI to run, e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/orders-api:latest"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU, 512 = 0.5 vCPU, etc.)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "How many copies of this task to keep running"
  type        = number
  default     = 1
}

variable "assign_public_ip" {
  description = "Give tasks a public IP. Only needed if subnets are public, which usually isn't the case here"
  type        = bool
  default     = false
}

variable "execution_role_arn" {
  description = "ARN of the IAM role ECS uses to pull the image and write logs, from the iam module"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the IAM role your application code uses, from the iam module"
  type        = string
}

variable "ingress_rules" {
  description = "Inbound rules to open on this service's security group. Empty by default"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Extra tags to merge into every resource this module creates"
  type        = map(string)
  default     = {}
}