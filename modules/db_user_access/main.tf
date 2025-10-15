# Add a null resource to ensure dependencies are met
resource "null_resource" "wait_for_secrets" {
  # This triggers when the secret ARNs change, ensuring secrets exist
  triggers = {
    rds_admin_secret_arn = var.rds_admin_secret_arn
    base_schema_secret_arn = var.base_schema_secret_arn
    user_secret_arns = jsonencode(var.user_secret_arns)
  }
}

# Get RDS admin credentials
data "aws_secretsmanager_secret_version" "rds_admin" {
    secret_id = var.rds_admin_secret_arn
    depends_on = [null_resource.wait_for_secrets]
}

# Get base schema credentials  
data "aws_secretsmanager_secret_version" "base_schema" {
    secret_id = var.base_schema_secret_arn
    depends_on = [null_resource.wait_for_secrets]
}

# Get individual user credentials
data "aws_secretsmanager_secret_version" "user_secrets" {
    for_each  = var.users
    secret_id = var.user_secret_arns[each.key]
    depends_on = [null_resource.wait_for_secrets]
}

locals {
  rds_admin = jsondecode(data.aws_secretsmanager_secret_version.rds_admin.secret_string)
  base_schema_creds = jsondecode(data.aws_secretsmanager_secret_version.base_schema.secret_string)
}

provider "mysql" {
  endpoint = "${var.db_endpoint}:${var.db_port}"
  username = var.environment == "local" ? "root" : local.rds_admin.username
  password = var.environment == "local" ? "rootpassword" : local.rds_admin.password
  tls      = "false"
}

# Create the main shared database
resource "mysql_database" "shared_database" {
  name                  = var.db_name
  default_character_set = "utf8"
  default_collation     = "utf8_general_ci"
}

# Create base schema (shared collaboration space)
resource "mysql_database" "base_schema" {
  name                  = "base_schema"
  default_character_set = "utf8"
  default_collation     = "utf8_general_ci"
  depends_on           = [mysql_database.shared_database]
}

# Create individual schemas for each user
resource "mysql_database" "user_schemas" {
  for_each              = var.users
  name                  = "${var.environment}-${replace(var.aws_region, "-", "")}-${each.value.username}_schema"
  default_character_set = "utf8"
  default_collation     = "utf8_general_ci"
}

# Create base schema user (for shared collaboration)
resource "mysql_user" "base_user" {
  user               = local.base_schema_creds.username  # "base_schema_user"
  host               = "%"
  plaintext_password = local.base_schema_creds.password
}

# Create individual users
resource "mysql_user" "users" {
  for_each           = var.users
  user               = "${var.environment}-${replace(var.aws_region, "-", "")}-${each.value.username}"
  host               = "%"
  plaintext_password = jsondecode(data.aws_secretsmanager_secret_version.user_secrets[each.key].secret_string)["password"]
  depends_on         = [mysql_database.user_schemas]
}

# Grant base user full access to base schema
resource "mysql_grant" "base_user_grant" {
    user       = mysql_user.base_user.user
    host       = mysql_user.base_user.host
    database   = mysql_database.base_schema.name
    privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER", "INDEX"]
}

# Grant individual users access to base schema (collaboration)
resource "mysql_grant" "user_base_grants" {
    for_each   = mysql_user.users
    user       = each.value.user
    host       = each.value.host
    database   = mysql_database.base_schema.name
    privileges = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

# Grant individual users full access to their own schema
resource "mysql_grant" "user_schema_grants" {
    for_each   = mysql_user.users
    user       = each.value.user
    host       = each.value.host
    database   = mysql_database.user_schemas[each.key].name
    privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER", "INDEX"]
}