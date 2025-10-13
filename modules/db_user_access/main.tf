data "aws_secretsmanager_secret_version" "rds_master" {
    secret_id = var.rds_master_secret_arn
}

locals {
  rds_master = jsondecode(data.aws_secretsmanager_secret_version.rds_master.secret_string)
}

provider "mysql" {
  endpoint = "${var.db_endpoint}:${var.db_port}"
  username = local.rds_master.username
  password = local.rds_master.password
  tls      = "false"
}

#schema
resource "db_schema" "schemas" {
  for_each = var.users
  name     = "${var.environment}-${each.value.username}-schema"
  depends_on = [module.user_secrets]
  tags = merge(
    var.tag,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
  
}

resource "db_user" "users" {
  for_each = var.users
  name     = "${var.environment}-${each.value.username}"
  host     = var.host
  plaintext_password = module.user_secrets[each.key].password
  depends_on = [db_schema.schemas]
  tags = merge(
    var.tag,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "db_user_grants" "grants" {
    for_each = db_user.users
    user     = each.value.user
    host     = each.value.host
    database   = db_schema.schemas[each.key].name
    privileges = [
        "SELECT",
        "INSERT",
        "UPDATE",
        "DELETE"
    ]
    depends_on = [db_user.users]
}