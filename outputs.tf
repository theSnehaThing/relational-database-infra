output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "database_name" {
  description = "Shared database name"
  value       = local.db_name
}

output "base_schema_name" {
  description = "Base schema for collaboration"
  value       = module.db_user_access.base_schema_name
}

output "user_schemas" {
  description = "Individual user schemas"
  value       = module.db_user_access.user_schemas
}

output "rds_admin_secret_arn" {
  description = "RDS admin secret ARN"
  value       = module.rds.rds_admin_secret_arn
}

output "base_schema_secret_arn" {
  description = "Base schema secret ARN"
  value       = module.rds.base_schema_secret_arn
}