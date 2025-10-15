resource "random_password" "rds_master_password" {
    length  = 16
    special = true
}

# DB Admin Secret (separate from user access)
resource "aws_secretsmanager_secret" "rds_admin_secret" {
    name        = "${var.environment}-rds-admin-secret"
    description = "RDS admin credentials for ${var.environment} environment"
    tags = {
        Environment = var.environment
        Project     = "RelationalDatabase"
        SecretType  = "DatabaseAdmin"
    }
}

resource "aws_secretsmanager_secret_version" "rds_admin_secret_version" {
    secret_id = aws_secretsmanager_secret.rds_admin_secret.id
    secret_string = jsonencode({
        username = var.master_username
        password = random_password.rds_master_password.result
    })
}

# Base Schema Secret (separate for shared collaboration)
resource "random_password" "base_schema_password" {
    length  = 12
    special = false  # Simpler password for shared use
}

resource "aws_secretsmanager_secret" "base_schema_secret" {
    name        = "${var.environment}-base-schema-secret"
    description = "Base schema credentials for ${var.environment} environment"
    tags = {
        Environment = var.environment
        Project     = "RelationalDatabase"
        SecretType  = "BaseSchema"
    }
}

resource "aws_secretsmanager_secret_version" "base_schema_secret_version" {
    secret_id = aws_secretsmanager_secret.base_schema_secret.id
    secret_string = jsonencode({
        username = "base_schema_user"
        password = random_password.base_schema_password.result
        schema   = "base_schema"
    })
}

# RDS instance - only create for non-LocalStack environments
resource "aws_db_instance" "this" {
    count = contains(["local", "localstack", "sso-local", "sso-test"], var.environment) ? 0 : 1
    
    identifier     = "${var.environment}-rds-instance"
    engine         = var.db_engine
    engine_version = var.db_engine_version
    instance_class = var.db_instance_class
    allocated_storage = var.db_allocated_storage
    storage_encrypted = true

    # Use shared database name
    db_name  = var.db_name
    username = var.master_username
    password = random_password.rds_master_password.result

    vpc_security_group_ids = [aws_security_group.rds_sg[0].id]
    
    skip_final_snapshot = true
    deletion_protection = false

    tags = merge(var.tag, {
        Environment = var.environment
        Project     = "RelationalDatabase"
    })
}

# Security group - only create for non-LocalStack environments
resource "aws_security_group" "rds_sg" {
    count = contains(["local", "localstack", "sso-local", "sso-test"], var.environment) ? 0 : 1
    
    name_prefix = "${var.environment}-rds-sg"
    description = "Security group for RDS instance"

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = merge(var.tag, {
        Environment = var.environment
        Project     = "RelationalDatabase"
    })
}