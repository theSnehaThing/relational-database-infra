resource "random_password" "rds_master_password" {
    length  = 16
    special = true
}

resource "aws_secretsmanager_secret" "rds_master_secret" {
    name        = "${var.environment}-rds-master-secret"
    description = "RDS master password for ${var.environment} environment"
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
}

resource "aws_secretsmanager_secret_version" "rds_master_secret_version" {
    secret_id     = aws_secretsmanager_secret.rds_master_secret.id
    secret_string = jsonencode({
      username = aws_db_instance.this.username
      password = random_password.rds_master_password.result
      host     = aws_db_instance.this.address
      port    = aws_db_instance.this.port
      db_name  = var.db_name
    })
    depends_on = [ aws_db_instance.this ]
}

resource "aws_db_instance" "this" {
    identifier = "${var.environment}-rds-instance"
    instance_class = var.db_instance_class
    engine = var.db_engine
    engine_version = var.db_engine_version
    allocated_storage = var.db_allocated_storage
    db_name = var.db_name
    username = var.master_username
    password = random_password.rds_master_password.result
    publicly_accessible = var.publicly_accessible
    skip_final_snapshot = true
    tags = merge(var.tag, {
      Name = "${var.environment}-rds-instance"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = var.aws_region
    })
  
}

output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "name" {
  value = aws_db_instance.this.port
}

output "rds_master_secret_arn" {
    value = aws_secretsmanager_secret.rds_master_secret.arn
}