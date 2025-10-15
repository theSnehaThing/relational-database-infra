locals {
  users = {
    for idx, user in var.user : tostring(idx) => {
      username = split("@", user.email)[0]
      role     = user.role
      first_name = user.first_name
      last_name  = user.last_name
      email      = user.email
    }
  }
  
  # New database naming convention: sol-(env)-(state)-(region)-shared-database
  db_name = "sol-${var.environment}-${var.db_state}-${replace(var.aws_region, "-", "")}-shared-database"
  
  # Resource naming convention: env-awsregion-
  resource_prefix = "${var.environment}-${replace(var.aws_region, "-", "")}"
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
    tag = {
      Environment = var.environment
      Project     = "RelationalDatabase"
      Region      = var.aws_region
      State       = var.db_state
    }
}



module "user_secrets" {
  source = "./modules/secrets"
  for_each = local.users
  port = module.rds.db_port
  aws_region = var.aws_region
  username = "${local.resource_prefix}-${split("@", each.value.email)[0]}"
  schema = "${var.environment}-${replace(var.aws_region, "-", "")}-${split("@", each.value.email)[0]}_schema"
  environment = var.environment
  host = module.rds.db_endpoint
  db_name = local.db_name
  tag = {
    Environment = var.environment
    Project     = "RelationalDatabase"
    Region      = var.aws_region
    State       = var.db_state
  }
}

module "user_iam" {
  source = "./modules/iam"
  aws_region = var.aws_region
  environment = var.environment
  for_each = local.users
  username = split("@", each.value.email)[0]
  secret_arn = module.user_secrets[each.key].secret_arn
  tag = {
    Environment = var.environment
    Project     = "RelationalDatabase"
    Region      = var.aws_region
    State       = var.db_state
  }
}

module "db_user_access" {
  source = "./modules/db_user_access"
  aws_region = var.aws_region
  rds_admin_secret_arn = module.rds.rds_admin_secret_arn
  base_schema_secret_arn = module.rds.base_schema_secret_arn
  create_users = var.create_user
  users = local.users
  environment = var.environment
  db_name = local.db_name
  db_endpoint = module.rds.db_endpoint
  db_port = module.rds.db_port
  user_secret_arns = { for k, v in module.user_secrets : k => v.secret_arn }
  tag = {
    Environment = var.environment
    Project     = "RelationalDatabase"
    Region      = var.aws_region
    State       = var.db_state
  }
}

