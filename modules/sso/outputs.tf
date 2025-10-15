# SSO Outputs (Real AWS)
output "sso_user_id" {
  description = "SSO User ID"
  value       = local.is_localstack ? "localstack-simulated" : aws_identitystore_user.database_user[0].user_id
}

output "sso_username" {
  description = "SSO Username"
  value       = local.is_localstack ? aws_iam_user.sso_simulation_user[0].name : aws_identitystore_user.database_user[0].user_name
}

output "sso_user_display_name" {
  description = "SSO User Display Name"
  value       = local.is_localstack ? "${var.first_name} ${var.last_name}" : aws_identitystore_user.database_user[0].display_name
}

output "permission_set_arn" {
  description = "Permission set ARN"
  value       = local.is_localstack ? "localstack-simulated-permission-set" : aws_ssoadmin_permission_set.database_access[0].arn
}

output "permission_set_name" {
  description = "Permission set name"
  value       = local.is_localstack ? "${var.environment}-database-${var.role}-${var.username}" : aws_ssoadmin_permission_set.database_access[0].name
}

output "sso_start_url" {
  description = "SSO start URL"
  value       = local.is_localstack ? "http://localhost:4566 (LocalStack SSO Simulation)" : "https://your-sso-domain.awsapps.com/start"
}

# LocalStack Simulation Outputs
output "iam_user_arn" {
  description = "IAM User ARN (LocalStack simulation)"
  value       = local.is_localstack ? aws_iam_user.sso_simulation_user[0].arn : null
}