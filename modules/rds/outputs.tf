output "db_endpoint" {
    value = var.environment == "local" ? "localhost" : aws_db_instance.this[0].endpoint
}

output "db_port" {
    value = var.environment == "local" ? "3306" : aws_db_instance.this[0].port
}

output "db_name" {
    value = var.environment == "local" ? "shared_dev_db" : aws_db_instance.this[0].db_name
}

output "rds_admin_secret_arn" {
    value = aws_secretsmanager_secret.rds_admin_secret.arn
}

output "base_schema_secret_arn" {
    value = aws_secretsmanager_secret.base_schema_secret.arn
}