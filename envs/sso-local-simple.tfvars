# Simple SSO Local Environment Configuration (No RDS)
aws_region = "eu-west-1"
environment = "sso-local"
db_state = "active"

# Disable RDS creation for local testing
create_rds = false

# Enable SSO instead of IAM users
use_sso = true
create_user = true

# User Configuration for SSO (simplified)
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