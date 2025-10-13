resource "random_password" "user_password" {
  length           = 16
  special          = true
  
}

resource "aws_secretsmanager_secret" "secrets" {

  name        = "${var.username}-${var.environment}-db-secret-${var.suffix}"
  description = "Secret for database user ${each.username} in ${var.environment} environment"
  tags = merge(
    var.tag,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
  
}


resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secrets.id
  secret_string = jsonencode({
    username = "${var.environment}-${var.username}"
    password = random_password.user_password.result
    host     = var.host
    db_name  = var.db_name
    port     = var.port
    schema   = "${var.environment}-${var.username}-schema"
  })
}

output "secret_arn" {
  value = aws_secretsmanager_secret.secrets.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.secrets.name
}