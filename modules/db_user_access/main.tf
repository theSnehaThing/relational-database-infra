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
resource "mysql_dbschema" "schemas" {
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

resource "mysql_user" "users" {
  for_each = var.users
  name     = "${var.environment}-${each.value.username}"
  host     = var.db_endpoint
  plaintext_password = each.value.password
  depends_on = [mysql_dbschema.schemas]
  tags = merge(
    var.tag,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "mysql_user_grants" "grants" {
    for_each = mysql_user.users
    user     = each.value.user
    host     = each.value.host
    database   = mysql_dbschema.schemas[each.key].name
    privileges = [
        "SELECT",
        "INSERT",
        "UPDATE",
        "DELETE"
    ]
}