variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "The environment to create resources in."
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the database."
  type        = string
}

variable "db_engine" {
  description = "The database engine to use."
  type        = string
  default = "mysql"
}

variable "db_engine_version" {
  description = "The version of the database engine."
  type        = string
  default     = "8.0"
}

variable "state" {
  description = "State or project state (e.g. active, archive, etc.)"
  type        = string
  default     = "active"
}

locals {
  db_name = "${var.environment}-${var.aws_region}-${var.state}-database"
}

output "db_name" {
  value = local.db_name
}

variable "publicly_accessible" {
    description = "Whether the database should be publicly accessible."
    type        = bool
    default     = false
}

variable "db_allocated_storage" {
  description = "The allocated storage for the database in gigabytes."
  type        = number
  default     = 20
}

variable "user" {
    description = "The username for a database user."
    type        = list(object({
      first_name = string
      last_name  = string
      email      = string
      username   = string
    }))
    default = [ {
      first_name = ""
      last_name  = ""
      email      = ""
      username   = ""
    } ]
}

#toggle user creation in mysql
variable "create_user" {
  description = "Whether to create a database user."
  type        = bool
  default     = true
}