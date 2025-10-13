locals {
  users = {for idx, user in var.user : tostring((idx)) => user}
  db_name = "${var.environment}-${var.aws_region}-${var.state}-database"
}

module "rds" {
    source = "./modules/rds"
    environment = var.environment
    aws_region = var.aws_region
    db_name = local.db_name
    db_instance_class = var.db_instance_class
    db_engine = var.db_engine
    db_engine_version = var.db_engine_version
    db_allocated_storage = var.db_allocated_storage
    publicly_accessible = var.publicly_accessible
    master_username = "adminuser"
    tag = {
      Environment = var.environment
      Project     = "RelationalDatabase"
    }
  
}



resource "random_string" "user_suffix" {
  for_each = local.users
  length = 4
  special = false
}

module "user_secrets" {
  source = "./modules/secrets"
  for_each = local.users
  port = module.rds.db_port
  aws_region = var.aws_region
  username = "${var.environment}-${each.value.username}"
  suffix = random_string.user_suffix[each.key].result
  schema = "${each.value}-${var.environment}-schema"
  environment = var.environment
  host = module.rds.db_endpoint
  db_name = local.db_name
  tag = {
    Environment = var.environment
    Project     = "RelationalDatabase"
    Region      = var.aws_region
  }
}

module "user_iam" {
  source = "./modules/iam"
  aws_region = var.aws_region
  environment = var.environment
  for_each = module.user_secrets
  username = each.value.username
  secret_arn = each.value.secret_arn
  suffix = random_string.user_suffix[each.key].result
  tag = {
    Environment = var.environment
    Project     = "RelationalDatabase"
    Region      = var.aws_region
  }
}

module "db_user_access" {
  source = "./modules/db_user_access"
  providers = {
    mysql = mysql
  }
  aws_region = var.aws_region
  rds_master_secret_arn = module.rds.rds_master_secret_arn
  create_users = var.create_user
  users = local.users
  environment = var.environment
  db_endpoint = module.rds.db_endpoint
  db_port =  module.rds.db_port
  tag = {
    Environment = var.environment
    Project     = "RelationalDatabase"
    Region      = var.aws_region
  }
}
