output "secret_arn" {
  value = aws_secretsmanager_secret.secrets.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.secrets.name
}