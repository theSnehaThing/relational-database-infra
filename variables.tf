variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance"
  type        = number
  default     = 20
}

variable "publicly_accessible" {
  description = "Whether RDS instance should be publicly accessible"
  type        = bool
  default     = false
}

variable "create_user" {
  description = "Whether to create database users"
  type        = bool
  default     = true
}

variable "user" {
  description = "List of users to create"
  type = list(object({
    first_name = string
    last_name  = string
    email      = string
    role       = optional(string, "developer")
  }))
}

variable "db_state" {
  description = "Database state (active, archive, primary, secondary)"
  type        = string
  default     = "active"
  
  validation {
    condition     = contains(["active", "archive", "primary", "secondary"], var.db_state)
    error_message = "Database state must be one of: active, archive, primary, secondary."
  }
}

variable "use_sso" {
  description = "Whether to use AWS SSO instead of IAM users"
  type        = bool
  default     = false
}