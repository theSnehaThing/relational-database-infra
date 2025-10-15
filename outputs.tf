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

# SSO Outputs (only when use_sso = true)
output "sso_users" {
  description = "SSO users information"
  value = var.use_sso ? {
    for k, v in module.user_sso : k => {
      user_id = v.sso_user_id
      username = v.sso_username
      display_name = v.sso_user_display_name
      permission_set_arn = v.permission_set_arn
    }
  } : {}
}

output "sso_start_url" {
  description = "SSO start URL for user login"
  value = var.use_sso ? "Configure your SSO domain in AWS Console" : "Not using SSO"
}

# IAM Outputs (only when use_sso = false)
output "iam_users" {
  description = "IAM users (when not using SSO)"
  value = var.use_sso ? {} : {
    for k, v in module.user_iam : k => {
      username = v.iam_username
      arn = v.iam_user_arn
    }
  }
}