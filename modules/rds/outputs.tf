output "db_endpoint" {
    value = aws_db_instance.this.endpoint
  
}

output "db_port" {
    value = aws_db_instance.this.port
}

output "rds_master_secret_arn" {
  value = aws_secretsmanager_secret.rds_master_secret.arn
}