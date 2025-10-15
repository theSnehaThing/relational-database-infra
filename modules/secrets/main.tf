resource "random_password" "user_password" {
  length           = 16
  special          = true
  
}

resource "aws_secretsmanager_secret" "secrets" {
  name        = "${var.environment}-${var.username}-db-secret"
  description = "Secret for database user ${var.username} in ${var.environment} environment"
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
    username = var.username
    password = random_password.user_password.result
    host     = var.host
    db_name  = var.db_name
    port     = var.port
    schema   = var.schema
  })
}
