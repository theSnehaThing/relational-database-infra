# SSO-Only Local Configuration (No Database/RDS)
aws_region = "eu-west-1" 
environment = "sso-test"
db_state = "active"

# Database Configuration (dummy values for local testing)
db_instance_class = "db.t3.micro"
db_engine = "mysql" 
db_engine_version = "8.0"
db_allocated_storage = 20
publicly_accessible = false

# Enable SSO mode
use_sso = true
create_user = false  # Don't create database users for testing
create_rds = false   # Disable RDS for LocalStack Community limitations

# User Configuration for SSO Testing
user = [
  {
    first_name = "TestUser"
    last_name  = "SSOTest" 
    email      = "testuser@example.com"
    role       = "developer"
  },
  {
    first_name = "Admin"
    last_name  = "SSOAdmin"
    email      = "admin@example.com" 
    role       = "admin"
  }
]