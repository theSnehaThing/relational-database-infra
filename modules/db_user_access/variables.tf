variable "aws_region" {
  type = string
}

variable "rds_admin_secret_arn" {
  description = "ARN of the RDS admin secret"
  type        = string
}

variable "base_schema_secret_arn" {
  description = "ARN of the base schema secret"
  type        = string
}

variable "create_users" {
  type = bool
}

variable "users" {
  description = "Map of users to create"
  type = map(object({
    username = string
    role     = string
    first_name = string
    last_name  = string
    email      = string
  }))
}

variable "environment" {
  type = string
}

variable "db_name" {
  description = "Name of the shared database"
  type        = string
}

variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type = string
}

variable "user_secret_arns" {
  description = "Map of user secret ARNs"
  type        = map(string)
}

variable "tag" {
  type = map(string)
}

output "shared_database_name" {
  description = "Name of the shared database"
  value       = mysql_database.shared_database.name
}

output "base_schema_name" {
  description = "Name of the shared base schema"
  value       = mysql_database.base_schema.name
}

output "user_schemas" {
  description = "Map of user schemas created"
  value       = { for k, v in mysql_database.user_schemas : k => v.name }
}

output "base_user" {
  description = "Base schema username"
  value       = mysql_user.base_user.user
}

output "database_users" {
  description = "Map of database users created"
  value       = { for k, v in mysql_user.users : k => v.user }
}
