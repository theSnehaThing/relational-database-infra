provider "aws" {
    region = var.aws_region
    access_key = "test"
    secret_key = "test"
    s3_use_path_style = true

    endpoints {
      iam = "http://localhost:4566"
      secretsmanager = "http://localhost:4566"
      rds = "http://localhost:4566"
    }
}

provider "random" {
  
}

