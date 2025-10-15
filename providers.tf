provider "aws" {
  region = var.aws_region
  
  # LocalStack configuration - when environment contains "local"
  dynamic "endpoints" {
    for_each = contains(["local", "localstack", "sso-local", "sso-test"], var.environment) ? [1] : []
    content {
      apigateway     = "http://localhost:4566"
      cloudformation = "http://localhost:4566"
      cloudwatch     = "http://localhost:4566"
      dynamodb       = "http://localhost:4566"
      ec2            = "http://localhost:4566"
      es             = "http://localhost:4566"
      firehose       = "http://localhost:4566"
      iam            = "http://localhost:4566"
      kinesis        = "http://localhost:4566"
      lambda         = "http://localhost:4566"
      rds            = "http://localhost:4566"
      redshift       = "http://localhost:4566"
      route53        = "http://localhost:4566"
      s3             = "http://localhost:4566"
      secretsmanager = "http://localhost:4566"
      ses            = "http://localhost:4566"
      sns            = "http://localhost:4566"
      sqs            = "http://localhost:4566"
      ssm            = "http://localhost:4566"
      stepfunctions  = "http://localhost:4566"
      sts            = "http://localhost:4566"
    }
  }

  # Local credentials and settings
  access_key                  = contains(["local", "sso-local", "sso-test"], var.environment) ? "test" : null
  secret_key                  = contains(["local", "sso-local", "sso-test"], var.environment) ? "test" : null
  s3_use_path_style          = contains(["local", "sso-local", "sso-test"], var.environment) ? true : null
  skip_credentials_validation = contains(["local", "sso-local", "sso-test"], var.environment) ? true : false
  skip_metadata_api_check     = contains(["local", "sso-local", "sso-test"], var.environment) ? true : false
  skip_region_validation      = contains(["local", "sso-local", "sso-test"], var.environment) ? true : false
  skip_requesting_account_id  = contains(["local", "sso-local", "sso-test"], var.environment) ? true : false
}

provider "random" {
  
}

# Add the MySQL provider with correct source
provider "mysql" {
  endpoint = "${module.rds.db_endpoint}:${module.rds.db_port}"
  username = "admin"
  password = "" # This will be retrieved from secrets manager
}



